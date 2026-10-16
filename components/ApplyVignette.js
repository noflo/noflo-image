import { Component, IP } from "@noflo/noflo";

/**
 * Applies a vignette effect to a canvas: a darkened outer edge plus a
 * lightened center, drawn with radial gradients.
 *
 * Requires a canvas engine with composite operations; the pureimage
 * engine does not support `globalCompositeOperation`, so the component
 * fails explicitly there instead of rendering a wrong-looking result.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Apply a vignette effect to a given image",
    icon: "file-image-o",
    inPorts: {
      canvas: {
        datatype: "object",
        description: "Canvas to apply the effect to",
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
    if (!input.hasData("canvas")) {
      return;
    }
    const canvas = input.getData("canvas");
    const ctx = canvas.getContext("2d");
    if (!("globalCompositeOperation" in ctx)) {
      output.error(
        new Error(
          "Vignette requires a canvas engine with composite operations — use the browser engine",
        ),
      );
      output.done();
      return;
    }
    const width = canvas.width;
    const height = canvas.height;
    const outerRadius = Math.sqrt((width / 2) ** 2 + (height / 2) ** 2);

    // Adds outer darkened blur effect
    /** @type {Record<string, unknown>} */ (
      /** @type {unknown} */ (ctx)
    ).globalCompositeOperation = "source-over";
    let gradient = ctx.createRadialGradient(
      width / 2,
      height / 2,
      0,
      width / 2,
      height / 2,
      outerRadius,
    );
    gradient.addColorStop(0, "rgba(0, 0, 0, 0)");
    gradient.addColorStop(0.65, "rgba(0, 0, 0, 0)");
    gradient.addColorStop(1, "rgba(0, 0, 0, 0.9)");
    ctx.fillStyle = /** @type {string} */ (/** @type {unknown} */ (gradient));
    ctx.fillRect(0, 0, width, height);

    // Adds central lighten effect
    /** @type {Record<string, unknown>} */ (
      /** @type {unknown} */ (ctx)
    ).globalCompositeOperation = "lighter";
    gradient = ctx.createRadialGradient(
      width / 2,
      height / 2,
      0,
      width / 2,
      height / 2,
      outerRadius,
    );
    gradient.addColorStop(0, "rgba(255, 255, 255, 0.1)");
    gradient.addColorStop(0.65, "rgba(255, 255, 255, 0)");
    gradient.addColorStop(1, "rgba(0, 0, 0, 0)");
    ctx.fillStyle = /** @type {string} */ (/** @type {unknown} */ (gradient));
    ctx.fillRect(0, 0, width, height);

    output.sendDone({ canvas: new IP("data", canvas, { clonable: false }) });
  });

  return c;
}
