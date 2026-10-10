import { Component } from "@noflo/noflo";

/**
 * Calculates the aspect ratio from image dimensions, reduced by the
 * greatest common divisor.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Calculate aspect ratio from image dimensions",
    icon: "file-image-o",
    inPorts: {
      dimensions: {
        datatype: "object",
        description: "Dimensions with width and height",
        required: true,
      },
    },
    outPorts: {
      ratio: {
        datatype: "object",
        description: "Object with a ratio string and a numeric aspect",
      },
      error: {
        datatype: "object",
      },
    },
  });

  c.process((input, output) => {
    if (!input.hasData("dimensions")) {
      return;
    }
    const dimensions = input.getData("dimensions");
    if (!(dimensions?.width > 0)) {
      output.error(new Error("Dimension is missing width"));
      output.done();
      return;
    }
    if (!(dimensions?.height > 0)) {
      output.error(new Error("Dimension is missing height"));
      output.done();
      return;
    }
    // Greatest common divisor
    /**
     * @param {number} a
     * @param {number} b
     * @returns {number}
     */
    const gcd = (a, b) => (b === 0 ? a : gcd(b, a % b));
    const divisor = gcd(dimensions.width, dimensions.height);
    const numerator = dimensions.width / divisor;
    const denominator = dimensions.height / divisor;
    output.sendDone({
      ratio: {
        ratio: `${numerator}:${denominator}`,
        aspect: numerator / denominator,
      },
    });
  });

  return c;
}
