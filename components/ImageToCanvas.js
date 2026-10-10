import { createCanvas } from "@noflo/canvas/engine";
import { Component } from "@noflo/noflo";

/**
 * Draws an image onto a canvas at full size. Accepts any drawable source:
 * a canvas object, or — in browsers — an image or video element. For
 * image bytes use `image/BufferToCanvas` first.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Convert image to canvas",
    icon: "file-image-o",
    inPorts: {
      image: {
        datatype: "object",
        description: "Image to draw: canvas, or a browser image element",
        required: true,
      },
    },
    outPorts: {
      canvas: {
        datatype: "object",
        description: "Canvas with the image drawn at full size",
      },
      error: {
        datatype: "object",
      },
    },
  });

  c.process((input, output) => {
    if (!input.hasData("image")) {
      return;
    }
    const image = input.getData("image");
    if (!(image?.width > 0) || !(image?.height > 0)) {
      output.error(new Error("Image is missing width or height"));
      output.done();
      return;
    }
    const canvas = createCanvas(image.width, image.height);
    const ctx = canvas.getContext("2d");
    ctx.drawImage(image, 0, 0);
    output.sendDone({ canvas });
  });

  return c;
}
