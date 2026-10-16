import { Component, IP } from "@noflo/noflo";
import jsfeat from "../lib/vendor/jsfeat.js";

/**
 * Runs a Canny edge detector over the canvas, replacing the image with
 * its edges in place.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Canny edge detector",
    icon: "file-image-o",
    inPorts: {
      canvas: {
        datatype: "object",
        description: "Canvas to process",
        required: true,
      },
      low: {
        datatype: "number",
        description: "Low hysteresis threshold",
        required: false,
        control: true,
        default: 20,
      },
      high: {
        datatype: "number",
        description: "High hysteresis threshold",
        required: false,
        control: true,
        default: 50,
      },
      kernel: {
        datatype: "number",
        description: "Gaussian blur kernel radius",
        required: false,
        control: true,
        default: 6,
      },
    },
    outPorts: {
      canvas: {
        datatype: "object",
        description: "Canvas with the edges drawn",
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
    const low = input.hasData("low") ? input.getData("low") : 20;
    const high = input.hasData("high") ? input.getData("high") : 50;
    const kernel = input.hasData("kernel") ? input.getData("kernel") : 6;
    const canvas = input.getData("canvas");
    try {
      const context = canvas.getContext("2d");
      const img = context.getImageData(0, 0, canvas.width, canvas.height);

      const imgU8 = new jsfeat.matrix_t(
        canvas.width,
        canvas.height,
        jsfeat.U8_t | jsfeat.C1_t,
      );
      // The 1.x component called grayscale with only two arguments and
      // used the class properties instead of its own locals; both were
      // broken
      jsfeat.imgproc.grayscale(img.data, canvas.width, canvas.height, imgU8);
      jsfeat.imgproc.gaussian_blur(imgU8, imgU8, kernel, 0);
      jsfeat.imgproc.canny(imgU8, imgU8, low, high);

      const imgU32 = new Uint32Array(img.data.buffer);
      const alpha = 0xff << 24;
      let i = imgU8.cols * imgU8.rows;
      while (i > 0) {
        i -= 1;
        const pix = imgU8.data[i];
        imgU32[i] = alpha | (pix << 16) | (pix << 8) | pix;
      }

      context.putImageData(img, 0, 0);
      output.sendDone({ canvas: new IP("data", canvas, { clonable: false }) });
    } catch (error) {
      output.error(error instanceof Error ? error : new Error(String(error)));
      output.done();
    }
  });

  return c;
}
