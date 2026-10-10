import { Component } from "@noflo/noflo";

/**
 * Adjusts the saturation of a canvas in place.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Adjust saturation level of a given image",
    icon: "file-image-o",
    inPorts: {
      canvas: {
        datatype: "object",
        description: "Canvas to adjust",
        required: true,
      },
      level: {
        datatype: "number",
        description: "Saturation change in percent (-100..100)",
        required: false,
        control: true,
        default: 100,
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
    const level = input.hasData("level") ? input.getData("level") : 100;
    const ctx = canvas.getContext("2d");
    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
    const data = imageData.data;
    const shift = level * -0.01;
    for (let i = 0; i < data.length; i += 4) {
      const max = Math.max(data[i], data[i + 1], data[i + 2]);
      if (data[i] !== max) {
        data[i] += (max - data[i]) * shift;
      }
      if (data[i + 1] !== max) {
        data[i + 1] += (max - data[i + 1]) * shift;
      }
      if (data[i + 2] !== max) {
        data[i + 2] += (max - data[i + 2]) * shift;
      }
    }
    ctx.putImageData(imageData, 0, 0);
    output.sendDone({ canvas });
  });

  return c;
}
