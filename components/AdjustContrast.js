import { Component, IP } from "@noflo/noflo";

/**
 * Adjusts the contrast of a canvas in place.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Adjust contrast level of a given image",
    icon: "file-image-o",
    inPorts: {
      canvas: {
        datatype: "object",
        description: "Canvas to adjust",
        required: true,
      },
      level: {
        datatype: "number",
        description: "Contrast multiplier (0 = flat, 1 = unchanged)",
        required: false,
        control: true,
        default: 1,
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
    const level = input.hasData("level") ? input.getData("level") : 1;
    const ctx = canvas.getContext("2d");
    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
    const data = imageData.data;
    const factor = (Number.parseFloat(level) || 0) + 1;
    for (let i = 0; i < data.length; i += 4) {
      data[i] = ((data[i] / 255 - 0.5) * factor + 0.5) * 255;
      data[i + 1] = ((data[i + 1] / 255 - 0.5) * factor + 0.5) * 255;
      data[i + 2] = ((data[i + 2] / 255 - 0.5) * factor + 0.5) * 255;
    }
    ctx.putImageData(imageData, 0, 0);
    output.sendDone({ canvas: new IP("data", canvas, { clonable: false }) });
  });

  return c;
}
