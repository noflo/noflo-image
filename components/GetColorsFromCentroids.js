import { Component } from "@noflo/noflo";

/**
 * Extracts the color at each path's centroid.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Extract color of path's centroid",
    icon: "file-image-o",
    inPorts: {
      canvas: {
        datatype: "object",
        description: "Canvas to sample",
        required: true,
      },
      paths: {
        datatype: "array",
        description: "Paths whose centroid colors to extract",
        required: true,
      },
    },
    outPorts: {
      colors: {
        datatype: "array",
        description: "CSS rgb() color per path",
      },
      error: {
        datatype: "object",
      },
    },
  });

  c.process((input, output) => {
    if (!input.hasData("canvas", "paths")) {
      return;
    }
    const [canvas, paths] = input.getData("canvas", "paths");
    const ctx = canvas.getContext("2d");
    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);

    const colors = paths.map((/** @type {any} */ path) => {
      const points = path.items;
      let sumx = 0;
      let sumy = 0;
      for (const point of points) {
        sumx += point.x;
        sumy += point.y;
      }
      const centroid = {
        x: Math.floor(sumx / points.length),
        y: Math.floor(sumy / points.length),
      };
      const offset = (centroid.x + centroid.y * canvas.width) * 4;
      const r = imageData.data[offset];
      const g = imageData.data[offset + 1];
      const b = imageData.data[offset + 2];
      return `rgb(${r}, ${g}, ${b})`;
    });

    output.sendDone({ colors });
  });

  return c;
}
