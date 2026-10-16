import { createCanvas, decodeImage } from "@noflo/canvas/engine";
import { Component, IP } from "@noflo/noflo";
import { decompressFrames, parseGIF } from "gifuct-js";

/**
 * Extracts a frame of a GIF as a canvas. Frames are composed cumulatively
 * from the start of the animation up to the requested frame; GIFs using
 * the restore-to-previous disposal method render slightly differently
 * than in a full animation player. Non-GIF images pass through to PNG/JPEG
 * decoding.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Extract a frame of a given GIF as a canvas",
    icon: "image",
    inPorts: {
      buffer: {
        datatype: "all",
        description: "GIF image bytes",
        required: true,
      },
      frame: {
        datatype: "int",
        description: "Frame index to extract",
        required: false,
        control: true,
        default: 0,
      },
    },
    outPorts: {
      canvas: {
        datatype: "object",
        description: "Canvas with the requested frame composed",
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
    const frameIndex = input.hasData("frame") ? input.getData("frame") : 0;
    (async () => {
      try {
        const gif = parseGIF(bytes);
        const frames = decompressFrames(gif, true);
        if (frameIndex >= frames.length) {
          throw new Error(
            `GIF has ${frames.length} frames; requested frame ${frameIndex}`,
          );
        }
        const canvas = createCanvas(gif.lsd.width, gif.lsd.height);
        const ctx = canvas.getContext("2d");
        // Compose the animation up to the requested frame, copying only
        // the opaque pixels of each frame patch
        for (let i = 0; i <= frameIndex; i += 1) {
          const frame = frames[i];
          const base = ctx.getImageData(0, 0, gif.lsd.width, gif.lsd.height);
          const { width, height, top, left } = frame.dims;
          for (let y = 0; y < height; y += 1) {
            for (let x = 0; x < width; x += 1) {
              const sourceIndex = (y * width + x) * 4;
              if (frame.patch[sourceIndex + 3] === 0) {
                continue;
              }
              const targetIndex = ((top + y) * gif.lsd.width + (left + x)) * 4;
              base.data[targetIndex] = frame.patch[sourceIndex];
              base.data[targetIndex + 1] = frame.patch[sourceIndex + 1];
              base.data[targetIndex + 2] = frame.patch[sourceIndex + 2];
              base.data[targetIndex + 3] = frame.patch[sourceIndex + 3];
            }
          }
          ctx.putImageData(base, 0, 0);
        }
        output.sendDone({
          canvas: new IP("data", canvas, { clonable: false }),
        });
      } catch (gifError) {
        // Not a GIF: fall back to PNG/JPEG decoding of the full image
        try {
          const image = await decodeImage(bytes);
          const canvas = createCanvas(image.width, image.height);
          canvas
            .getContext("2d")
            .drawImage(image, 0, 0, image.width, image.height);
          output.sendDone({
            canvas: new IP("data", canvas, { clonable: false }),
          });
        } catch {
          output.error(
            gifError instanceof Error ? gifError : new Error(String(gifError)),
          );
          output.done();
        }
      }
    })();
  });

  return c;
}
