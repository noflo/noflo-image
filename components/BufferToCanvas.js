import { createCanvas, decodeImage } from "@noflo/canvas/engine";
import { Component, IP } from "@noflo/noflo";

/**
 * Decodes image bytes (PNG or JPEG) onto a canvas. GIF frames are handled
 * by `image/GetGIFFrame` instead.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Convert image bytes to a canvas",
    icon: "expand",
    inPorts: {
      buffer: {
        datatype: "all",
        description: "Image bytes",
        required: true,
      },
    },
    outPorts: {
      canvas: {
        datatype: "object",
        description: "Canvas with the decoded image drawn at full size",
      },
      error: {
        datatype: "object",
      },
    },
  });

  c.process((input, output) => {
    if (!input.hasData("buffer")) {
      return;
    }
    const bytes = input.getData("buffer");
    decodeImage(bytes)
      .then(async (image) => {
        const canvas = createCanvas(image.width, image.height);
        const ctx = canvas.getContext("2d");
        ctx.drawImage(image, 0, 0, image.width, image.height);
        output.sendDone({
          canvas: new IP("data", canvas, { clonable: false }),
        });
      })
      .catch((error) => {
        output.error(error instanceof Error ? error : new Error(String(error)));
        output.done();
      });
  });

  return c;
}
