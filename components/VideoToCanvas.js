import { Component } from "@noflo/noflo";

/**
 * Draws a video element's current frame onto a canvas, repeating with
 * animation frames. Browser-only: fails explicitly outside a browser
 * environment instead of crashing on the missing DOM.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Convert video to canvas",
    icon: "file-image-o",
    inPorts: {
      video: {
        datatype: "object",
        description: "Video element to draw to canvas",
        required: true,
      },
      canvas: {
        datatype: "object",
        description: "Optional canvas to draw onto; created when absent",
        required: false,
      },
    },
    outPorts: {
      canvas: {
        datatype: "object",
        description: "Canvas with each video frame drawn",
      },
      error: {
        datatype: "object",
      },
    },
  });

  c.process((input, output) => {
    if (!input.hasData("video")) {
      return;
    }
    if (typeof document === "undefined") {
      output.error(
        new Error("VideoToCanvas requires a browser environment with a DOM"),
      );
      output.done();
      return;
    }
    const video = input.getData("video");
    if (video?.tagName !== "VIDEO") {
      output.error(new Error("Video must be a VIDEO DOM element"));
      output.done();
      return;
    }
    let canvas;
    if (input.hasData("canvas")) {
      canvas = input.getData("canvas");
    } else {
      if (!video.videoWidth) {
        // Metadata not loaded yet
        output.error(new Error("Video width not available"));
        output.done();
        return;
      }
      canvas = document.createElement("canvas");
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
    }
    const ctx = canvas.getContext("2d");
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
    output.sendDone({ canvas });
  });

  return c;
}
