import { canvasToPng } from "@noflo/canvas/engine";
import { Component } from "@noflo/noflo";

/**
 * Encodes a canvas to PNG image bytes. Unlike the 1.x component this is
 * isomorphic: browsers encode through the Blob API, Node.js through
 * pureimage. For other formats use `canvas/SaveJPEG`.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Convert a canvas to PNG image bytes",
    icon: "picture-o",
    inPorts: {
      canvas: {
        datatype: "object",
        description: "Canvas to encode",
        required: true,
      },
    },
    outPorts: {
      buffer: {
        datatype: "all",
        description: "PNG image bytes",
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
    canvasToPng(input.getData("canvas"))
      .then((bytes) => {
        output.sendDone({ buffer: bytes });
      })
      .catch((error) => {
        output.error(error instanceof Error ? error : new Error(String(error)));
        output.done();
      });
  });

  return c;
}
