import { Component } from "@noflo/noflo";

/**
 * Determines the orientation of an image from its dimensions.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Get orientation from image dimensions",
    icon: "file-image-o",
    inPorts: {
      dimensions: {
        datatype: "object",
        description: "Dimensions with width and height",
        required: true,
      },
    },
    outPorts: {
      orientation: {
        datatype: "object",
        description:
          "Object with an orientation string: landscape, portrait, or square",
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
    let orientation = "square";
    if (dimensions.width > dimensions.height) {
      orientation = "landscape";
    }
    if (dimensions.width < dimensions.height) {
      orientation = "portrait";
    }
    output.sendDone({ orientation: { orientation } });
  });

  return c;
}
