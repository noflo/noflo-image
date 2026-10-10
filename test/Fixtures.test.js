import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { describe, it } from "node:test";
import * as noflo from "@noflo/noflo";
import { createCanvas, decodeImage } from "@noflo/canvas/engine";

import { getComponent as getAdjustBrightness } from "../components/AdjustBrightness.js";
import { getComponent as getAdjustContrast } from "../components/AdjustContrast.js";
import { getComponent as getAdjustSaturation } from "../components/AdjustSaturation.js";
import { getComponent as getApplyAdjustmentCurve } from "../components/ApplyAdjustmentCurve.js";
import { getComponent as getExtractLightness } from "../components/ExtractLightness.js";
import { getComponent as getExtractSaturation } from "../components/ExtractSaturation.js";
import { getComponent as getGetGIFFrame } from "../components/GetGIFFrame.js";
import { presets } from "../lib/presets.js";

/**
 * Loads a spec fixture image as a canvas.
 * @param {string} name
 * @returns {Promise<import("@noflo/canvas/engine").CanvasLike>}
 */
const fixtureCanvas = async (name) => {
  const bytes = new Uint8Array(
    readFileSync(new URL(`./fixtures/${name}`, import.meta.url)),
  );
  const image = await decodeImage(bytes);
  const canvas = createCanvas(image.width, image.height);
  canvas.getContext("2d").drawImage(image, 0, 0, image.width, image.height);
  return canvas;
};

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
    }, 10000);
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
 * Wires every input socket first, then posts in order, returning the
 * first data value.
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

/**
 * Asserts every channel byte stays within tolerance of the reference
 * image. The 1.x suite used a threshold of 1.5 with the same JPEG
 * decoder on both sides; these comparisons cross decoders (pureimage
 * jpeg-js against the libjpeg the references were generated with), so
 * the tolerance absorbs decoder variance while still catching real
 * logic errors.
 * @param {import("@noflo/canvas/engine").CanvasLike} result
 * @param {import("@noflo/canvas/engine").CanvasLike} reference
 * @param {number} threshold
 * @returns {void}
 */
const assertCloseTo = (result, reference, threshold = 8) => {
  const resultData = result.getContext("2d").getImageData(0, 0, result.width, result.height).data;
  const referenceData = reference.getContext("2d").getImageData(0, 0, reference.width, reference.height).data;
  assert.equal(resultData.length, referenceData.length);
  for (let i = 0; i < resultData.length; i += 1) {
    const difference = Math.abs(referenceData[i] - resultData[i]);
    if (difference > threshold) {
      assert.fail(
        `Pixel difference ${difference} at byte ${i}: ${referenceData[i]} vs ${resultData[i]}`,
      );
    }
  }
};

describe("Fixture regressions against 1.x reference images", () => {
  it("AdjustBrightness matches brightness.png", async () => {
    const c = getAdjustBrightness();
    try {
      const result = await run(c, "canvas", {
        level: 10,
        canvas: await fixtureCanvas("original.jpg"),
      });
      assertCloseTo(result, await fixtureCanvas("brightness.png"));
    } finally {
      await c.shutdown();
    }
  });
  it("AdjustContrast matches contrast.png", async () => {
    const c = getAdjustContrast();
    try {
      const result = await run(c, "canvas", {
        level: 1,
        canvas: await fixtureCanvas("original.jpg"),
      });
      assertCloseTo(result, await fixtureCanvas("contrast.png"));
    } finally {
      await c.shutdown();
    }
  });
  it("AdjustSaturation matches saturation.png", async () => {
    const c = getAdjustSaturation();
    try {
      const result = await run(c, "canvas", {
        level: 100,
        canvas: await fixtureCanvas("original.jpg"),
      });
      assertCloseTo(result, await fixtureCanvas("saturation.png"));
    } finally {
      await c.shutdown();
    }
  });
  it("ApplyAdjustmentCurve matches colorcurve.png with the xproii preset", async () => {
    const c = getApplyAdjustmentCurve();
    try {
      const result = await run(c, "canvas", {
        curve: presets.xproii,
        canvas: await fixtureCanvas("original.jpg"),
      });
      assertCloseTo(result, await fixtureCanvas("colorcurve.png"));
    } finally {
      await c.shutdown();
    }
  });
  it("ExtractLightness separates light and dark images", async () => {
    const c = getExtractLightness();
    try {
      const light = await run(c, "lightness", {
        canvas: await fixtureCanvas("light.png"),
      });
      assert.ok(light > 0, `light: ${light}`);
      const dark = await run(c, "lightness", {
        canvas: await fixtureCanvas("dark.png"),
      });
      assert.ok(dark < 0, `dark: ${dark}`);
    } finally {
      await c.shutdown();
    }
  });
  it("ExtractSaturation separates saturated and muted images", async () => {
    const c = getExtractSaturation();
    try {
      const saturated = await run(c, "saturation", {
        canvas: await fixtureCanvas("saturation.png"),
      });
      assert.ok(saturated > 0, `saturated: ${saturated}`);
      const muted = await run(c, "saturation", {
        canvas: await fixtureCanvas("muted.png"),
      });
      assert.ok(muted < 0, `muted: ${muted}`);
    } finally {
      await c.shutdown();
    }
  });
  it("GetGIFFrame extracts frames from real animated GIFs", async () => {
    const c = getGetGIFFrame();
    try {
      const animated = new Uint8Array(
        readFileSync(new URL("./fixtures/animated.gif", import.meta.url)),
      );
      const canvas = await run(c, "canvas", { buffer: animated, frame: 0 });
      assert.ok(canvas.width > 0);
      assert.ok(canvas.height > 0);
    } finally {
      await c.shutdown();
    }
  });
});
