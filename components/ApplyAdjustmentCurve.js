import { Component, IP } from "@noflo/noflo";

/**
 * Applies an RGBA adjustment curve to a canvas in place. The curve object
 * carries per-channel lookup tables (`r`, `g`, `b`) and an overall table
 * (`a`) applied after the channel ones.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Apply an RGBA adjustment curve to a given image",
    icon: "file-image-o",
    inPorts: {
      canvas: {
        datatype: "object",
        description: "Canvas to adjust",
        required: true,
      },
      curve: {
        datatype: "object",
        description: "Adjustment curve with r, g, b, and a lookup tables",
        required: true,
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
    if (!input.hasData("canvas", "curve")) {
      return;
    }
    const [canvas, curve] = input.getData("canvas", "curve");
    const ctx = canvas.getContext("2d");
    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
    const data = imageData.data;
    // From the original created by TechSlides at http://techslides.com
    // Instagram filter from http://matthewruddy.github.io/jQuery-filter.me
    for (let i = 0; i < data.length; i += 4) {
      data[i] = curve.r[data[i]];
      data[i + 1] = curve.g[data[i + 1]];
      data[i + 2] = curve.b[data[i + 2]];
      // Apply the overall RGB contrast changes to each pixel
      data[i] = curve.a[data[i]];
      data[i + 1] = curve.a[data[i + 1]];
      data[i + 2] = curve.a[data[i + 2]];
    }
    ctx.putImageData(imageData, 0, 0);
    output.sendDone({ canvas: new IP("data", canvas, { clonable: false }) });
  });

  return c;
}
