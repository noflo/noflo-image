import { Component } from "@noflo/noflo";

/**
 * Loads an image over HTTP(S) or from a data: URL and emits the raw image
 * bytes. Local file paths are out of scope — use `@noflo/filesystem` to
 * read files and feed the bytes here.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Load image from URL and output image bytes",
    icon: "picture-o",
    inPorts: {
      url: {
        datatype: "string",
        description: "HTTP(S) or data: URL of the image",
        required: true,
      },
    },
    outPorts: {
      buffer: {
        datatype: "all",
        description: "Image bytes",
      },
      error: {
        datatype: "object",
      },
    },
  });

  c.process((input, output) => {
    if (!input.hasData("url")) {
      return;
    }
    const url = input.getData("url");
    fetch(url)
      .then(async (response) => {
        if (!response.ok) {
          throw new Error(`${url} responded with ${response.status}`);
        }
        const bytes = new Uint8Array(await response.arrayBuffer());
        if (bytes.length === 0) {
          throw new Error(`${url} responded with zero bytes`);
        }
        output.sendDone({ buffer: bytes });
      })
      .catch((error) => {
        output.error(error instanceof Error ? error : new Error(String(error)));
        output.done();
      });
  });

  return c;
}
