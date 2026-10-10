import { Component } from "@noflo/noflo";
import { presets } from "../lib/presets.js";

/**
 * Gets a preset RGBA adjustment curve by name for use with
 * `image/ApplyAdjustmentCurve`.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Get a preset for a RGBA adjustment curve",
    icon: "file-image-o",
    inPorts: {
      presetname: {
        datatype: "string",
        description: "Preset name",
        required: true,
        values: Object.keys(presets),
      },
    },
    outPorts: {
      curve: {
        datatype: "object",
        description: "Adjustment curve with r, g, b, and a lookup tables",
      },
      error: {
        datatype: "object",
      },
    },
  });

  c.process((input, output) => {
    if (!input.hasData("presetname")) {
      return;
    }
    const name = input.getData("presetname");
    if (!presets[name]) {
      output.error(new Error(`Preset '${name}' not available`));
      output.done();
      return;
    }
    output.sendDone({ curve: presets[name] });
  });

  return c;
}
