import { Component } from "@noflo/noflo";
import { converter } from "culori";

const toHsl = converter("hsl");
const toHcl = converter("lch");

// Perceptual brightness, CIE Y'601. Input: sRGB channels in 0..255
/** @param {number} r @param {number} g @param {number} b */
const cieY601 = (r, g, b) =>
  0.299 * (r / 255) + 0.587 * (g / 255) + 0.114 * (b / 255);

/**
 * @param {Uint8ClampedArray} data
 * @param {Record<string, number[]>} res
 * @param {number} i
 * @returns {void}
 */
const addEntry = (data, res, i) => {
  const [r, g, b, a] = [data[i], data[i + 1], data[i + 2], data[i + 3]];
  const y = Math.floor(cieY601(r, g, b) * 255);
  res.r[r] += 1;
  res.g[g] += 1;
  res.b[b] += 1;
  res.a[a] += 1;
  res.y[y] += 1;
  const hsl = toHsl({ mode: "rgb", r: r / 255, g: g / 255, b: b / 255 });
  const hcl = toHcl({ mode: "rgb", r: r / 255, g: g / 255, b: b / 255 });
  const h = Math.round(hsl?.h ?? 0) | 0;
  const s = ((hsl?.s ?? 0) * 100) | 0;
  const l = ((hsl?.l ?? 0) * 100) | 0;
  const chroma = Math.round(hcl?.c ?? 0) | 0;
  res.h[h] += 1;
  res.s[s] += 1;
  res.l[l] += 1;
  res.c[chroma] += 1;
};

/**
 * Calculates RGBAY and HSCL histograms of a canvas, normalized so that
 * 1.0 means all pixels share that channel value.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Calculate RGBAY and HSCL histograms of a given canvas",
    icon: "file-image-o",
    inPorts: {
      canvas: {
        datatype: "object",
        description: "Canvas to analyze",
        required: true,
      },
      step: {
        datatype: "number",
        description: "Pixel sampling step",
        required: false,
        control: true,
        default: 1,
      },
    },
    outPorts: {
      histogram: {
        datatype: "object",
        description: "Histogram with r, g, b, a, y, h, s, c, l bins",
      },
      error: {
        datatype: "object",
      },
    },
  });

  c.process((input, output) => {
    if (!input.hasData("canvas")) {
      return;
    }
    const canvas = input.getData("canvas");
    if (!(canvas?.width > 0) || !(canvas?.height > 0)) {
      output.error(
        new Error("Failed to compute histogram. Canvas has zero dimensions"),
      );
      output.done();
      return;
    }
    const step = Math.round(input.hasData("step") ? input.getData("step") : 1);
    const rgba = 4;
    const effectiveStep =
      step < 1 || step * rgba > canvas.width * canvas.height * 4 ? 1 : step;
    const pixels = (canvas.width * canvas.height) / effectiveStep;
    const ctx = canvas.getContext("2d");
    const data = ctx.getImageData(0, 0, canvas.width, canvas.height).data;
    /** @type {Record<string, number[]>} */
    const result = {
      r: new Array(256).fill(0),
      g: new Array(256).fill(0),
      b: new Array(256).fill(0),
      a: new Array(256).fill(0),
      y: new Array(256).fill(0),
      h: new Array(361).fill(0), // degrees [0..360] -> [0..361)
      s: new Array(101).fill(0), // [0.0..1.0] -> [0..101)
      c: new Array(135).fill(0), // https://github.com/gka/chroma.js/issues/63
      l: new Array(101).fill(0),
    };
    for (let index = 0; index < data.length; index += effectiveStep * rgba) {
      addEntry(data, result, index);
    }
    // Normalize such that 1.0 means all pixels have this color
    for (const key of Object.keys(result)) {
      const histogram = result[key];
      for (let i = 0; i < histogram.length; i += 1) {
        histogram[i] /= pixels;
      }
    }
    output.sendDone({ histogram: result });
  });

  return c;
}
