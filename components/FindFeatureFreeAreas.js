import { Component } from "@noflo/noflo";
import { findRegions } from "../lib/FindRegions.js";

/**
 * Grows candidate rectangles from an evenly spaced grid over the image,
 * bounded by the detected feature corners, and emits the feature-free
 * regions sorted by area. Consumes the `corners` output of
 * `image/GetFeaturesYAPE`.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Find feature-free areas of an image from its feature corners",
    icon: "file-image-o",
    inPorts: {
      corners: {
        datatype: "array",
        description: "Feature corners with x and y coordinates",
        required: true,
      },
      width: {
        datatype: "int",
        description: "Image width in pixels",
        required: false,
        control: true,
        default: 0,
      },
      height: {
        datatype: "int",
        description: "Image height in pixels",
        required: false,
        control: true,
        default: 0,
      },
      segments: {
        datatype: "int",
        description: "Base number of starting-point segments",
        required: false,
        control: true,
        default: 4,
      },
    },
    outPorts: {
      areas: {
        datatype: "array",
        description: "Feature-free regions sorted by area",
      },
      corners: {
        datatype: "array",
        description: "The input corners, forwarded",
      },
      error: {
        datatype: "object",
      },
    },
  });

  c.process((input, output) => {
    if (!input.hasData("corners")) {
      return;
    }
    const width = input.hasData("width") ? input.getData("width") : 0;
    const height = input.hasData("height") ? input.getData("height") : 0;
    const segments = input.hasData("segments") ? input.getData("segments") : 4;
    const corners = input.getData("corners");
    try {
      const regions = findRegions(corners, { w: width, h: height }, segments);
      output.sendDone({ areas: regions, corners });
    } catch (error) {
      output.error(error instanceof Error ? error : new Error(String(error)));
      output.done();
    }
  });

  return c;
}
