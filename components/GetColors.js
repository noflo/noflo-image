import { Component, IP } from "@noflo/noflo";
import * as imageq from "image-q";

/**
 * Extracts the dominant colors of a canvas. The optional `css` control
 * switches the output from RGB tuples to CSS color strings.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Extract the dominant colors of an image",
    icon: "file-image-o",
    inPorts: {
      canvas: {
        datatype: "object",
        description: "Canvas to analyze",
        required: true,
      },
      css: {
        datatype: "boolean",
        description: "Emit CSS rgb() strings instead of RGB tuples",
        required: false,
        control: true,
        default: false,
      },
      colors: {
        datatype: "number",
        description: "How many dominant colors to extract",
        required: false,
        control: true,
        default: 10,
      },
    },
    outPorts: {
      colors: {
        datatype: "array",
        description: "Dominant colors as RGB tuples or CSS strings",
      },
      canvas: {
        datatype: "object",
        description: "The analyzed canvas",
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
    const useCss = input.hasData("css") ? input.getData("css") : false;
    const colorCount = input.hasData("colors") ? input.getData("colors") : 10;
    if (!(canvas?.width > 0) || !(canvas?.height > 0)) {
      output.error(
        new Error("Error when trying to get colors: canvas is undefined"),
      );
      output.done();
      return;
    }
    (async () => {
      try {
        const ctx = canvas.getContext("2d");
        const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
        const container = imageq.utils.PointContainer.fromImageData(
          /** @type {ImageData} */ (/** @type {unknown} */ (imageData)),
        );
        const palette = await imageq.buildPalette([container], {
          colors: colorCount,
        });
        const points = palette.getPointContainer().getPointArray();
        const colors = points.map((/** @type {any} */ point) =>
          useCss
            ? `rgb(${point.r}, ${point.g}, ${point.b})`
            : [point.r, point.g, point.b],
        );
        output.sendDone({
          canvas: new IP("data", canvas, { clonable: false }),
          colors,
        });
      } catch (error) {
        output.sendDone({
          canvas: new IP("data", canvas, { clonable: false }),
        });
        output.send({ colors: [] });
        output.done();
        const message = error instanceof Error ? error.message : String(error);
        console.warn(
          `Error when trying to get colors: ${message}. Sending an empty array.`,
        );
      }
    })();
  });

  return c;
}
