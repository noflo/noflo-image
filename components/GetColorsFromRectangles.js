import { createCanvas } from "@noflo/canvas/engine";
import { Component } from "@noflo/noflo";
import * as imageq from "image-q";

/**
 * Extracts dominant colors from rectangle regions of a canvas. Each
 * region is scaled onto a 200x200 staging canvas before quantization,
 * matching the 1.x behavior.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Extract colors from rectangle regions of a canvas",
    icon: "file-image-o",
    inPorts: {
      canvas: {
        datatype: "object",
        description: "Canvas to sample from",
        required: true,
      },
      rect: {
        datatype: "array",
        description: "Rectangles with x, y, width, height",
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
        description: "How many dominant colors to extract per region",
        required: false,
        control: true,
        default: 10,
      },
    },
    outPorts: {
      out: {
        datatype: "array",
        description: "One color array per rectangle",
      },
      error: {
        datatype: "object",
      },
    },
  });

  c.process((input, output) => {
    if (!input.hasData("canvas", "rect")) {
      return;
    }
    const [canvas, rects] = input.getData("canvas", "rect");
    const useCss = input.hasData("css") ? input.getData("css") : false;
    const colorCount = input.hasData("colors") ? input.getData("colors") : 10;
    (async () => {
      try {
        // Stitching pieces to 200x200 for now
        const piece = createCanvas(200, 200);
        const pieceCtx = piece.getContext("2d");
        /** @type {Array<Array<number[] | string>>} */
        const piecesColors = [];
        for (const rect of rects) {
          pieceCtx.drawImage(
            canvas,
            rect.x,
            rect.y,
            rect.width,
            rect.height,
            0,
            0,
            200,
            200,
          );
          const imageData = pieceCtx.getImageData(0, 0, 200, 200);
          const container = imageq.utils.PointContainer.fromImageData(
            /** @type {ImageData} */ (/** @type {unknown} */ (imageData)),
          );
          const palette = await imageq.buildPalette([container], {
            colors: colorCount,
          });
          const points = palette.getPointContainer().getPointArray();
          piecesColors.push(
            points.map((/** @type {any} */ point) =>
              useCss
                ? `rgb(${point.r}, ${point.g}, ${point.b})`
                : [point.r, point.g, point.b],
            ),
          );
        }
        output.sendDone({ out: piecesColors });
      } catch (error) {
        output.error(error instanceof Error ? error : new Error(String(error)));
        output.done();
      }
    })();
  });

  return c;
}
