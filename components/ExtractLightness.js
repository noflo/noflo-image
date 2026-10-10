import { Component } from "@noflo/noflo";

/**
 * Computes the global lightness of a canvas: the share of light pixels
 * minus the share of dark pixels (-1..1). Light images return values
 * greater than zero.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description:
      "Extract global lightness of a given image. Light images will return values greater than zero",
    icon: "file-image-o",
    inPorts: {
      canvas: {
        datatype: "object",
        description: "Canvas to analyze",
        required: true,
      },
    },
    outPorts: {
      lightness: {
        datatype: "number",
        description: "Lightness in the -1..1 range",
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
    let lightPixels = 0;
    let darkPixels = 0;
    // Middle intensity
    const threshold = 127;
    for (let i = 0; i < data.length; i += 4) {
      const max = Math.max(data[i], data[i + 1], data[i + 2]);
      if (max >= threshold) {
        lightPixels += 1;
      } else {
        darkPixels += 1;
      }
    }
    const imageArea = canvas.width * canvas.height;
    output.sendDone({ lightness: (lightPixels - darkPixels) / imageArea });
  });

  return c;
}
