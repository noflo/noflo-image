import { createCanvas } from "@noflo/canvas/engine";
import { Component } from "@noflo/noflo";

/**
 * Crops the given rectangle out of a canvas into a new canvas.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Crop the rectangle out of a given canvas",
    icon: "file-image-o",
    inPorts: {
      canvas: {
        datatype: "object",
        description: "Canvas to crop from",
        required: true,
      },
      rectangle: {
        datatype: "object",
        description: "Rectangle with x, y, width, height to crop out",
        required: true,
      },
    },
    outPorts: {
      canvas: {
        datatype: "object",
        description: "The cropped canvas",
      },
      error: {
        datatype: "object",
      },
    },
  });

  c.process((input, output) => {
    if (!input.hasData("canvas", "rectangle")) {
      return;
    }
    const [canvas, rectangle] = input.getData("canvas", "rectangle");
    if (
      rectangle.x === undefined ||
      rectangle.y === undefined ||
      rectangle.width === undefined ||
      rectangle.height === undefined
    ) {
      output.error(new Error("Rectangle is missing x, y, width or height"));
      output.done();
      return;
    }
    if (!(rectangle.width > 0) || !(rectangle.height > 0)) {
      output.error(
        new Error("Rectangle width or height is not a positive value"),
      );
      output.done();
      return;
    }
    if (!(canvas?.width > 0) || !(canvas?.height > 0)) {
      output.error(new Error("Canvas is missing width or height"));
      output.done();
      return;
    }
    let { x, y, width, height } = rectangle;
    if (width > canvas.width - x) {
      width = Math.abs(canvas.width - x);
    }
    if (height > canvas.height - y) {
      height = Math.abs(canvas.height - y);
    }
    if (x < 0) {
      x = 0;
    }
    if (y < 0) {
      y = 0;
    }
    const newCanvas = createCanvas(width, height);
    const newCtx = newCanvas.getContext("2d");
    newCtx.drawImage(canvas, x, y, width, height, 0, 0, width, height);
    const source = /** @type {Record<string, unknown>} */ (
      /** @type {unknown} */ (canvas)
    );
    const target = /** @type {Record<string, unknown>} */ (
      /** @type {unknown} */ (newCanvas)
    );
    if (source.originalWidth !== undefined) {
      target.originalWidth = source.originalWidth;
    }
    if (source.originalHeight !== undefined) {
      target.originalHeight = source.originalHeight;
    }
    output.sendDone({ canvas: newCanvas });
  });

  return c;
}
