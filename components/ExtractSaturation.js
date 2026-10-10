import { Component } from "@noflo/noflo";
import { converter } from "culori";

const toHsl = converter("hsl");

/**
 * Computes the global saturation of a canvas: the share of saturated
 * pixels minus the share of muted pixels (-1..1). Saturated images return
 * values greater than zero.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description:
      "Extract global saturation of a given image. Saturated images will return values greater than zero",
    icon: "file-image-o",
    inPorts: {
      canvas: {
        datatype: "object",
        description: "Canvas to analyze",
        required: true,
      },
    },
    outPorts: {
      saturation: {
        datatype: "number",
        description: "Saturation in the -1..1 range",
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
    const ctx = canvas.getContext("2d");
    const data = ctx.getImageData(0, 0, canvas.width, canvas.height).data;
    let saturatedPixels = 0;
    let mutedPixels = 0;
    // Middle intensity
    const threshold = 0.5;
    for (let i = 0; i < data.length; i += 4) {
      const hsl = toHsl({
        mode: "rgb",
        r: data[i] / 255,
        g: data[i + 1] / 255,
        b: data[i + 2] / 255,
      });
      if ((hsl?.s ?? 0) >= threshold) {
        saturatedPixels += 1;
      } else {
        mutedPixels += 1;
      }
    }
    const imageArea = canvas.width * canvas.height;
    output.sendDone({
      saturation: (saturatedPixels - mutedPixels) / imageArea,
    });
  });

  return c;
}
