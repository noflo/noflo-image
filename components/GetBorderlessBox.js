import { Component } from "@noflo/noflo";
import { getBorderlessBox } from "../lib/BorderlessBox.js";

/**
 * Extracts a bounding box with uniform borders removed, according to the
 * difference thresholds between neighbouring pixel rows and columns.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description:
      "Extract a bounding box with top and bottom borders removed (according to a certain threshold)",
    icon: "file-image-o",
    inPorts: {
      canvas: {
        datatype: "object",
        description: "Canvas to analyze",
        required: true,
      },
      mean: {
        datatype: "number",
        description: "Mean difference between neighbours at same row",
        required: false,
        control: true,
        default: 0.1,
      },
      max: {
        datatype: "number",
        description: "Maximal difference between neighbours at same row",
        required: false,
        control: true,
        default: 10,
      },
      avg: {
        datatype: "number",
        description: "Average difference between columns' neighbours",
        required: false,
        control: true,
        default: 10,
      },
    },
    outPorts: {
      rectangle: {
        datatype: "object",
        description: "Bounding box with borders removed",
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
    const canvas = input.getData("canvas");
    if (!(canvas?.width > 0) || !(canvas?.height > 0)) {
      output.error(
        new Error(
          "Error when trying to extract a bounding box. The canvas is missing",
        ),
      );
      output.done();
      return;
    }
    const thresholds = {
      mean: input.hasData("mean") ? input.getData("mean") : 0.1,
      max: input.hasData("max") ? input.getData("max") : 10,
      avg: input.hasData("avg") ? input.getData("avg") : 10,
    };
    try {
      const box = getBorderlessBox(canvas, thresholds);
      output.sendDone({ rectangle: box });
    } catch (error) {
      output.error(error instanceof Error ? error : new Error(String(error)));
      output.done();
    }
  });

  return c;
}
