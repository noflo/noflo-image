import { Component, IP } from "@noflo/noflo";

/**
 * Adjusts the brightness of a canvas in place.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Adjust brightness level of a given image",
    icon: "file-image-o",
    inPorts: {
      canvas: {
        datatype: "object",
        description: "Canvas to adjust",
        required: true,
      },
      level: {
        datatype: "number",
        description: "Brightness change in percent (-100..100)",
        required: false,
        control: true,
        default: 10,
      },
    },
    outPorts: {
      canvas: {
        datatype: "object",
        description: "The adjusted canvas",
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
    const level = input.hasData("level") ? input.getData("level") : 10;
    const ctx = canvas.getContext("2d");
    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
    const data = imageData.data;
    const shift = Math.floor(255 * (level / 100));
    for (let i = 0; i < data.length; i += 4) {
      data[i] += shift;
      data[i + 1] += shift;
      data[i + 2] += shift;
    }
    ctx.putImageData(imageData, 0, 0);
    output.sendDone({ canvas: new IP("data", canvas, { clonable: false }) });
  });

  return c;
}
