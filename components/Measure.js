import { Component } from "@noflo/noflo";
import { imageSize } from "image-size";

/**
 * Measures image dimensions from image bytes. Unlike the 1.x pair of
 * browser/node components this is a single isomorphic component working
 * on bytes; for URLs compose with `image/UrlToBuffer`.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Get image dimensions from image bytes",
    icon: "picture-o",
    inPorts: {
      buffer: {
        datatype: "all",
        description: "Image bytes",
        required: true,
      },
    },
    outPorts: {
      dimensions: {
        datatype: "object",
        description: "Dimensions with width and height",
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
    try {
      const dimensions = imageSize(bytes);
      output.sendDone({
        dimensions: { width: dimensions.width, height: dimensions.height },
      });
    } catch (error) {
      output.error(error instanceof Error ? error : new Error(String(error)));
      output.done();
    }
  });

  return c;
}
