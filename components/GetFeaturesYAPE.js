import { Component } from "@noflo/noflo";
import jsfeat from "../lib/vendor/jsfeat.js";

/**
 * Extracts feature corners of an image using the YAPE06 detector.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Extract feature corners of image (method: YAPE)",
    icon: "file-image-o",
    inPorts: {
      canvas: {
        datatype: "object",
        description: "Canvas to analyze",
        required: true,
      },
      laplacian_threshold: {
        datatype: "number",
        description: "YAPE06 laplacian threshold",
        required: false,
        control: true,
        default: 30,
      },
      min_eigen_threshold: {
        datatype: "number",
        description: "YAPE06 minimum eigen value threshold",
        required: false,
        control: true,
        default: 25,
      },
    },
    outPorts: {
      corners: {
        datatype: "array",
        description: "Detected corner keypoints",
      },
      canvas: {
        datatype: "object",
        description: "The analyzed canvas",
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
    const laplacian_threshold = input.hasData("laplacian_threshold")
      ? input.getData("laplacian_threshold")
      : 30;
    const min_eigen_threshold = input.hasData("min_eigen_threshold")
      ? input.getData("min_eigen_threshold")
      : 25;
    const canvas = input.getData("canvas");
    try {
      const context = canvas.getContext("2d");
      const img = context.getImageData(0, 0, canvas.width, canvas.height);

      jsfeat.yape06.laplacian_threshold = laplacian_threshold;
      jsfeat.yape06.min_eigen_value_threshold = min_eigen_threshold;

      const imgU8 = new jsfeat.matrix_t(
        canvas.width,
        canvas.height,
        jsfeat.U8_t | jsfeat.C1_t,
      );
      jsfeat.imgproc.grayscale(img.data, canvas.width, canvas.height, imgU8);
      jsfeat.imgproc.box_blur_gray(imgU8, imgU8, 2, 0);

      const pixels = canvas.width * canvas.height;
      /** @type {import("../lib/vendor/jsfeat.js").Keypoint[]} */
      const corners = [];
      for (let i = 0; i < pixels; i += 1) {
        corners.push(new jsfeat.keypoint_t(0, 0, 0));
      }
      const count = jsfeat.yape06.detect(imgU8, corners);

      output.sendDone({
        corners: corners.slice(0, count),
        canvas,
      });
    } catch (error) {
      output.error(error instanceof Error ? error : new Error(String(error)));
      output.done();
    }
  });

  return c;
}
