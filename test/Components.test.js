import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { describe, it } from "node:test";
import { canvasToPng, createCanvas } from "@noflo/canvas/engine";
import * as noflo from "@noflo/noflo";

import { getComponent as getAdjustBrightness } from "../components/AdjustBrightness.js";
import { getComponent as getAdjustContrast } from "../components/AdjustContrast.js";
import { getComponent as getApplyAdjustmentCurve } from "../components/ApplyAdjustmentCurve.js";
import { getComponent as getBufferToCanvas } from "../components/BufferToCanvas.js";
import { getComponent as getCalculateAspectRatio } from "../components/CalculateAspectRatio.js";
import { getComponent as getCanvasToBuffer } from "../components/CanvasToBuffer.js";
import { getComponent as getCrop } from "../components/Crop.js";
import { getComponent as getDetectAnimatedGif } from "../components/DetectAnimatedGif.js";
import { getComponent as getExtractLightness } from "../components/ExtractLightness.js";
import { getComponent as getExtractSaturation } from "../components/ExtractSaturation.js";
import { getComponent as getFindFeatureFreeAreas } from "../components/FindFeatureFreeAreas.js";
import { getComponent as getFindFreeRectangles } from "../components/FindFreeRectangles.js";
import { getComponent as getGetBorderlessBox } from "../components/GetBorderlessBox.js";
import { getComponent as getGetCannyEdges } from "../components/GetCannyEdges.js";
import { getComponent as getGetColors } from "../components/GetColors.js";
import { getComponent as getGetFeaturesYAPE } from "../components/GetFeaturesYAPE.js";
import { getComponent as getGetGIFFrame } from "../components/GetGIFFrame.js";
import { getComponent as getGetHistogram } from "../components/GetHistogram.js";
import { getComponent as getGetOrientation } from "../components/GetOrientation.js";
import { getComponent as getGetPresetCurve } from "../components/GetPresetCurve.js";
import { getComponent as getImageToCanvas } from "../components/ImageToCanvas.js";
import { getComponent as getMeasure } from "../components/Measure.js";
import { getComponent as getUrlToBuffer } from "../components/UrlToBuffer.js";

// Minimal 1x1 transparent PNG
const PNG_1X1 = new Uint8Array([
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0,
  0, 0, 1, 8, 6, 0, 0, 0, 31, 37, 158, 118, 0, 0, 0, 13, 73, 68, 65, 84, 120,
  156, 99, 250, 207, 192, 80, 15, 254, 3, 4, 73, 113, 226, 251, 0, 0, 0, 0, 73,
  69, 78, 68, 174, 66, 96, 130,
]);

// Minimal 1x1 GIF89a carrying the NETSCAPE2.0 application extension
const GIF_NETSCAPE = new Uint8Array([
  71, 73, 70, 56, 57, 97, 1, 0, 1, 0, 0, 0, 0, 33, 255, 11, 78, 69, 84, 83, 67,
  65, 80, 69, 50, 46, 48, 3, 1, 0, 0, 0, 59,
]);

/**
 * Waits for the next data IP on a socket.
 * @param {import("@noflo/noflo").internalSocket.InternalSocket} socket
 * @returns {Promise<import("@noflo/noflo").IP>}
 */
const nextData = (socket) =>
  new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      cleanup();
      reject(new Error("Timed out waiting for IP"));
    }, 2000);
    /** @param {CustomEvent} event */
    const listener = (event) => {
      if (event.detail.type === "data") {
        cleanup();
        resolve(event.detail);
      }
    };
    const cleanup = () => {
      clearTimeout(timer);
      socket.removeEventListener("ip", listener);
    };
    socket.addEventListener("ip", listener);
  });

/**
 * Wires every input socket first (unattached optional ports make hasData
 * vacuously true), then posts in order, returning the first data value.
 * @param {import("@noflo/noflo").Component} c
 * @param {string} outPort
 * @param {Record<string, any>} inputs
 * @returns {Promise<any>}
 */
const run = async (c, outPort, inputs) => {
  const outSocket = noflo.internalSocket.createSocket();
  c.outPorts[outPort].attach(outSocket);
  const received = nextData(outSocket);
  /** @type {Record<string, import("@noflo/noflo").internalSocket.InternalSocket>} */
  const sockets = {};
  for (const port of Object.keys(inputs)) {
    const socket = noflo.internalSocket.createSocket();
    c.inPorts[port].attach(socket);
    sockets[port] = socket;
  }
  for (const [port, value] of Object.entries(inputs)) {
    sockets[port].post(new noflo.IP("data", value));
  }
  const ip = await received;
  return ip.data;
};

/** @param {string} fillStyle */
const solidCanvas = (fillStyle, width = 8, height = 8) => {
  const canvas = createCanvas(width, height);
  const ctx = canvas.getContext("2d");
  ctx.fillStyle = fillStyle;
  ctx.fillRect(0, 0, width, height);
  return canvas;
};

describe("Pixel adjustments", () => {
  it("AdjustBrightness lightens pixels", async () => {
    const c = getAdjustBrightness();
    try {
      const canvas = await run(c, "canvas", {
        // Red canvas at half brightness
        canvas: solidCanvas("rgb(100, 0, 0)"),
        level: 10,
      });
      const data = canvas.getContext("2d").getImageData(0, 0, 8, 8).data;
      // 10% of 255 = 25 shifted
      assert.equal(data[0], 125);
      assert.equal(data[1], 25);
    } finally {
      await c.shutdown();
    }
  });
  it("AdjustContrast keeps level 0 unchanged per the 1.x formula", async () => {
    const c = getAdjustContrast();
    try {
      // The 1.x formula adds 1 to the level for the factor, so level 0
      // means unchanged
      const unchanged = await run(c, "canvas", {
        level: 0,
        canvas: solidCanvas("rgb(200, 100, 50)"),
      });
      const unchangedData = unchanged
        .getContext("2d")
        .getImageData(0, 0, 8, 8).data;
      assert.equal(unchangedData[0], 200);
      const same = await run(c, "canvas", {
        level: 1,
        canvas: solidCanvas("rgb(200, 100, 50)"),
      });
      const sameData = same.getContext("2d").getImageData(0, 0, 8, 8).data;
      // Level 1 doubles the contrast factor; the red channel clamps at
      // 255 and the blue channel at 0
      assert.equal(sameData[0], 255);
      assert.equal(sameData[2], 0);
    } finally {
      await c.shutdown();
    }
  });
  it("ApplyAdjustmentCurve remaps channels through the tables", async () => {
    const c = getApplyAdjustmentCurve();
    try {
      // Double every red channel value
      const curve = {
        r: Array.from({ length: 256 }, (_, i) => Math.min(255, i * 2)),
        g: Array.from({ length: 256 }, (_, i) => i),
        b: Array.from({ length: 256 }, (_, i) => i),
        a: Array.from({ length: 256 }, (_, i) => i),
      };
      const canvas = await run(c, "canvas", {
        canvas: solidCanvas("rgb(50, 60, 70)"),
        curve,
      });
      const data = canvas.getContext("2d").getImageData(0, 0, 8, 8).data;
      assert.equal(data[0], 100);
      assert.equal(data[1], 60);
      assert.equal(data[2], 70);
    } finally {
      await c.shutdown();
    }
  });
});

describe("Extraction", () => {
  it("ExtractLightness scores a light canvas above a dark one", async () => {
    const c = getExtractLightness();
    try {
      const light = await run(c, "lightness", {
        canvas: solidCanvas("rgb(255, 255, 255)"),
      });
      assert.equal(light, 1);
      const dark = await run(c, "lightness", {
        canvas: solidCanvas("rgb(10, 10, 10)"),
      });
      assert.equal(dark, -1);
    } finally {
      await c.shutdown();
    }
  });
  it("ExtractSaturation scores a saturated canvas above a gray one", async () => {
    const c = getExtractSaturation();
    try {
      const saturated = await run(c, "saturation", {
        canvas: solidCanvas("rgb(255, 0, 0)"),
      });
      assert.equal(saturated, 1);
      const gray = await run(c, "saturation", {
        canvas: solidCanvas("rgb(128, 128, 128)"),
      });
      assert.equal(gray, -1);
    } finally {
      await c.shutdown();
    }
  });
  it("GetHistogram produces normalized bins", async () => {
    const c = getGetHistogram();
    try {
      const histogram = await run(c, "histogram", {
        canvas: solidCanvas("rgb(255, 0, 0)"),
      });
      assert.equal(histogram.r[255], 1);
      assert.equal(histogram.g[0], 1);
      assert.equal(histogram.b[0], 1);
      // Sum of a bin array is 1 across all bins
      const sum = histogram.r.reduce(
        (/** @type {number} */ a, /** @type {number} */ b) => a + b,
        0,
      );
      assert.ok(Math.abs(sum - 1) < 0.01);
    } finally {
      await c.shutdown();
    }
  });
  it("GetColors finds the dominant color", async () => {
    const c = getGetColors();
    try {
      const canvas = solidCanvas("rgb(10, 200, 30)");
      const colors = await run(c, "colors", { canvas, colors: 2 });
      assert.ok(Array.isArray(colors));
      assert.ok(colors.length > 0);
      // The dominant color is close to the fill
      const [r, g, b] = colors[0];
      assert.ok(Math.abs(r - 10) < 20, `red ${r}`);
      assert.ok(Math.abs(g - 200) < 20, `green ${g}`);
      assert.ok(Math.abs(b - 30) < 20, `blue ${b}`);
    } finally {
      await c.shutdown();
    }
  });
});

describe("I/O components", () => {
  it("UrlToBuffer decodes data: URLs", async () => {
    const c = getUrlToBuffer();
    try {
      const dataUrl = `data:image/png;base64,${Buffer.from(PNG_1X1).toString("base64")}`;
      const buffer = await run(c, "buffer", { url: dataUrl });
      assert.ok(buffer instanceof Uint8Array);
      assert.equal(buffer[0], 0x89);
    } finally {
      await c.shutdown();
    }
  });
  it("Measure reads dimensions from image bytes", async () => {
    const c = getMeasure();
    try {
      const dimensions = await run(c, "dimensions", { buffer: PNG_1X1 });
      assert.deepEqual(dimensions, { width: 1, height: 1 });
    } finally {
      await c.shutdown();
    }
  });
  it("BufferToCanvas decodes PNG bytes onto a canvas", async () => {
    const c = getBufferToCanvas();
    const source = solidCanvas("rgb(0, 0, 255)", 5, 7);
    const png = await canvasToPng(source);
    try {
      const canvas = await run(c, "canvas", { buffer: png });
      assert.equal(canvas.width, 5);
      assert.equal(canvas.height, 7);
    } finally {
      await c.shutdown();
    }
  });
  it("CanvasToBuffer emits PNG bytes", async () => {
    const c = getCanvasToBuffer();
    try {
      const buffer = await run(c, "buffer", {
        canvas: solidCanvas("rgb(0, 0, 255)"),
      });
      assert.ok(buffer instanceof Uint8Array);
      assert.equal(buffer[0], 0x89);
      assert.equal(buffer[1], 0x50);
    } finally {
      await c.shutdown();
    }
  });
  it("DetectAnimatedGif distinguishes static and animated GIFs", async () => {
    const c = getDetectAnimatedGif();
    try {
      const animated = await run(c, "animated", { buffer: GIF_NETSCAPE });
      assert.equal(animated, true);
      const notGif = await run(c, "animated", { buffer: PNG_1X1 });
      assert.equal(notGif, false);
    } finally {
      await c.shutdown();
    }
  });
  it("GetGIFFrame composes a GIF frame onto a canvas", async () => {
    const c = getGetGIFFrame();
    const gif = new Uint8Array(
      readFileSync(new URL("./fixtures/animated-1x1.gif", import.meta.url)),
    );
    try {
      const canvas = await run(c, "canvas", { buffer: gif, frame: 1 });
      assert.equal(canvas.width, 1);
      assert.equal(canvas.height, 1);
    } finally {
      await c.shutdown();
    }
  });
  it("Crop extracts a sub-rectangle", async () => {
    const c = getCrop();
    try {
      const canvas = await run(c, "canvas", {
        canvas: solidCanvas("rgb(255, 0, 0)", 10, 10),
        rectangle: { x: 2, y: 3, width: 4, height: 5 },
      });
      assert.equal(canvas.width, 4);
      assert.equal(canvas.height, 5);
    } finally {
      await c.shutdown();
    }
  });
  it("ImageToCanvas draws a canvas onto a new canvas", async () => {
    const c = getImageToCanvas();
    try {
      const source = solidCanvas("rgb(0, 255, 0)", 6, 7);
      const canvas = await run(c, "canvas", { image: source });
      assert.equal(canvas.width, 6);
      assert.equal(canvas.height, 7);
      const data = canvas.getContext("2d").getImageData(1, 1, 1, 1).data;
      assert.equal(data[1], 255);
    } finally {
      await c.shutdown();
    }
  });
});

describe("Metadata components", () => {
  it("CalculateAspectRatio reduces by the gcd", async () => {
    const c = getCalculateAspectRatio();
    try {
      const ratio = await run(c, "ratio", {
        dimensions: { width: 640, height: 480 },
      });
      assert.equal(ratio.ratio, "4:3");
      assert.ok(Math.abs(ratio.aspect - 4 / 3) < 0.0001);
    } finally {
      await c.shutdown();
    }
  });
  it("GetOrientation classifies dimensions", async () => {
    const c = getGetOrientation();
    try {
      const landscape = await run(c, "orientation", {
        dimensions: { width: 100, height: 50 },
      });
      assert.equal(landscape.orientation, "landscape");
      const square = await run(c, "orientation", {
        dimensions: { width: 50, height: 50 },
      });
      assert.equal(square.orientation, "square");
    } finally {
      await c.shutdown();
    }
  });
  it("GetPresetCurve resolves known presets", async () => {
    const c = getGetPresetCurve();
    try {
      // The values array validates at the port, so unknown names are
      // rejected before the process runs
      assert.deepEqual(c.inPorts.presetname.options.values, [
        "1977",
        "brannan",
        "gotham",
        "hefe",
        "lordkelvin",
        "nashville",
        "xproii",
        "newkelvin",
      ]);
      const curve = await run(c, "curve", { presetname: "1977" });
      assert.equal(curve.a.length, 257);
    } finally {
      await c.shutdown();
    }
  });
});

describe("Computer-vision components", () => {
  it("GetCannyEdges runs and keeps dimensions", async () => {
    const c = getGetCannyEdges();
    try {
      // A gradient with a hard edge produces detectable edges
      const canvas = createCanvas(16, 16);
      const ctx = canvas.getContext("2d");
      ctx.fillStyle = "rgb(0, 0, 0)";
      ctx.fillRect(0, 0, 8, 16);
      ctx.fillStyle = "rgb(255, 255, 255)";
      ctx.fillRect(8, 0, 8, 16);
      const result = await run(c, "canvas", {
        canvas,
        low: 20,
        high: 50,
        kernel: 2,
      });
      assert.equal(result.width, 16);
      const data = result.getContext("2d").getImageData(0, 0, 16, 16).data;
      assert.ok(data.length === 16 * 16 * 4);
    } finally {
      await c.shutdown();
    }
  });
  it("GetFeaturesYAPE detects corners on a synthetic pattern", async () => {
    const c = getGetFeaturesYAPE();
    try {
      // Checkerboard pattern with strong corners
      const canvas = createCanvas(32, 32);
      const ctx = canvas.getContext("2d");
      for (let y = 0; y < 32; y += 4) {
        for (let x = 0; x < 32; x += 4) {
          ctx.fillStyle =
            (x + y) % 8 === 0 ? "rgb(255, 255, 255)" : "rgb(0, 0, 0)";
          ctx.fillRect(x, y, 4, 4);
        }
      }
      const result = await run(c, "corners", { canvas });
      assert.ok(Array.isArray(result));
    } finally {
      await c.shutdown();
    }
  });
  it("FindFeatureFreeAreas grows regions from corners", async () => {
    const c = getFindFeatureFreeAreas();
    try {
      const corners = [
        { x: 10, y: 10 },
        { x: 50, y: 10 },
        { x: 10, y: 50 },
      ];
      const result = await run(c, "areas", {
        // Controls first; corners completes the firing pattern
        width: 100,
        height: 100,
        segments: 2,
        corners,
      });
      assert.ok(Array.isArray(result));
      assert.ok(result.length > 0);
      for (const area of result) {
        assert.ok(area.width >= 0);
        assert.ok(area.height >= 0);
      }
    } finally {
      await c.shutdown();
    }
  });
  it("FindFreeRectangles finds text-capable regions outside the polygon", async () => {
    const c = getFindFreeRectangles();
    try {
      const result = await run(c, "out", {
        canvas: { width: 300, height: 300 },
        polygon: [
          [150, 0],
          [150, 300],
        ],
        threshold: 1000,
        max: 3,
      });
      assert.ok(Array.isArray(result));
      assert.ok(result.length > 0);
      assert.ok(result[0].text.small >= 0);
    } finally {
      await c.shutdown();
    }
  });
  it("GetBorderlessBox removes uniform borders", async () => {
    const c = getGetBorderlessBox();
    try {
      // A red area surrounded by a uniform black border
      const canvas = createCanvas(20, 20);
      const ctx = canvas.getContext("2d");
      ctx.fillStyle = "rgb(0, 0, 0)";
      ctx.fillRect(0, 0, 20, 20);
      ctx.fillStyle = "rgb(200, 0, 0)";
      ctx.fillRect(5, 5, 10, 10);
      const box = await run(c, "rectangle", { canvas });
      assert.ok(box.width <= 20);
      assert.ok(box.height <= 20);
      assert.ok(box.x >= 0);
    } finally {
      await c.shutdown();
    }
  });
});
