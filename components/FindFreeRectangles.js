import { Component } from "@noflo/noflo";
import { findFreeRectangles } from "../lib/FreeRectangles.js";

/**
 * Finds bounding rectangles of the regions outside the given salience
 * polygon, annotated with the font sizes each region fits.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description:
      "Find bounding rectangles of regions outside of the given polygon",
    icon: "file-image-o",
    inPorts: {
      canvas: {
        datatype: "object",
        description: "Canvas whose dimensions define the search bounds",
        required: true,
      },
      polygon: {
        datatype: "array",
        description: "Salience polygon",
        required: true,
      },
      threshold: {
        datatype: "number",
        description: "Minimum region area in pixels",
        required: false,
        control: true,
        default: 0,
      },
      max: {
        datatype: "number",
        description: "Maximum number of rectangles",
        required: false,
        control: true,
        default: 10,
      },
    },
    outPorts: {
      out: {
        datatype: "array",
        description: "Free rectangles sorted by area, largest first",
      },
      error: {
        datatype: "object",
      },
    },
  });

  c.process((input, output) => {
    if (!input.hasData("canvas", "polygon")) {
      return;
    }
    const [canvas, polygon] = input.getData("canvas", "polygon");
    const threshold = input.hasData("threshold")
      ? input.getData("threshold")
      : 0;
    const max = input.hasData("max") ? input.getData("max") : 10;
    try {
      const rects = findFreeRectangles(canvas, polygon, threshold, max);
      output.sendDone({ out: rects });
    } catch (error) {
      output.error(error instanceof Error ? error : new Error(String(error)));
      output.done();
    }
  });

  return c;
}
