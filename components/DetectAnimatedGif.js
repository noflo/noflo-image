import { Component, IP } from "@noflo/noflo";

// The GIF application extension that marks an animated GIF: an
// extension-introducer block carrying the NETSCAPE2.0 identifier
/** @type {number[]} */
const NETSCAPE_SIGNATURE = [
  0x21, 0xff, 0x0b, 0x4e, 0x45, 0x54, 0x53, 0x43, 0x41, 0x50, 0x45, 0x32, 0x2e,
  0x30,
];

/**
 * Detects whether GIF bytes contain the NETSCAPE2.0 application extension
 * that marks them as animated. Replaces the 1.x `animated-gif-detector`
 * dependency with a direct check.
 * @param {Uint8Array} bytes
 * @returns {boolean}
 */
export function isAnimatedGif(bytes) {
  outer: for (let i = 0; i < bytes.length; i += 1) {
    for (let j = 0; j < NETSCAPE_SIGNATURE.length; j += 1) {
      if (bytes[i + j] !== NETSCAPE_SIGNATURE[j]) {
        continue outer;
      }
    }
    return true;
  }
  return false;
}

/**
 * Detects whether a given GIF is animated. Non-GIF input yields false.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Detect if a given GIF is animated",
    icon: "expand",
    inPorts: {
      buffer: {
        datatype: "all",
        description: "Image bytes",
        required: true,
      },
    },
    outPorts: {
      animated: {
        datatype: "boolean",
        description: "Whether the bytes are an animated GIF",
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
    const buffer = input.getData("buffer");
    if (!(buffer instanceof Uint8Array) || buffer.length < 6) {
      output.sendDone({ animated: new IP("data", false, { clonable: false }) });
      return;
    }
    // GIF signature: GIF87a or GIF89a
    const isGif =
      buffer[0] === 0x47 && buffer[1] === 0x49 && buffer[2] === 0x46;
    output.sendDone({ animated: isGif ? isAnimatedGif(buffer) : false });
  });

  return c;
}
