import { Component } from "@noflo/noflo";

/**
 * Converts an image URL to a potential URL of the full-scale image for
 * known providers (Flickr, WordPress, Wikimedia, imgflo, Gravatar), then
 * verifies the candidate URL responds. When the candidate fails, the
 * original URL is sent.
 * @returns {import("@noflo/noflo").Component} The configured component
 */
export function getComponent() {
  const c = new Component({
    description: "Convert an image URL to potential URL of full-scale image",
    icon: "external-link",
    inPorts: {
      url: {
        datatype: "string",
        description: "Image URL",
        required: true,
      },
    },
    outPorts: {
      url: {
        datatype: "string",
        description: "Full-scale image URL candidate, or the original",
      },
      error: {
        datatype: "object",
      },
    },
  });

  c.process((input, output) => {
    if (!input.hasData("url")) {
      return;
    }
    const url = input.getData("url");
    if (!url) {
      output.error(new Error("No image source provided"));
      output.done();
      return;
    }
    if (typeof url !== "string") {
      output.error(new Error("URL is not a string"));
      output.done();
      return;
    }

    /** @type {string} */
    let newUrl = url;
    if (url.includes("staticflickr.com")) {
      // See docs in https://www.flickr.com/services/api/misc.urls.html
      const format = url.match(/_(.)\.(gif|png|jpg)/);
      if (format) {
        if (format[1] === "d") {
          // If is a downloading image, return original
          newUrl = url.replace(/_(.)\.(gif|png|jpg)/, ".$2");
        } else if (format[1] === "o") {
          // We already have the original
          newUrl = url;
        } else {
          // Another format, return large
          newUrl = url.replace(/_(.)\.(gif|png|jpg)/, "_b.$2");
        }
      } else {
        // Non-specified format, return large
        newUrl = url.replace(/\.(gif|png|jpg)/, "_b.$1");
      }
    }
    if (url.includes("wordpress.com")) {
      newUrl = url.replace(/\?w=[\d]+/, "");
    }
    if (url.includes("wikimedia.org")) {
      // The 1.x implementation computed the replacement but never
      // assigned it; the candidate is now actually used
      newUrl = url.replace(
        /\/commons\/thumb\/([0-9])\/([0-9][a-z])\/(.*[\\/])[^\\/]*$/,
        "/commons/$1/$2/$3",
      );
    }
    if (url.includes("imgflo")) {
      try {
        const parsed = new URL(url);
        const source = parsed.searchParams.get("input");
        if (source) {
          newUrl = source;
        }
      } catch {
        // Not a parseable URL, keep as-is
      }
    }
    if (url.includes("gravatar.com") && url.includes("/avatar/")) {
      // https://en.gravatar.com/site/implement/images/
      try {
        const parsed = new URL(url);
        if (!parsed.searchParams.has("s") && !parsed.searchParams.has("size")) {
          parsed.searchParams.set("size", "512");
        } else if (parsed.searchParams.has("s")) {
          parsed.searchParams.set("s", "512");
        } else {
          parsed.searchParams.set("size", "512");
        }
        newUrl = parsed.toString();
      } catch {
        // Not a parseable URL, keep as-is
      }
    }
    if (/[-_](small|thumbnail|thumb|tm)/.test(url) && newUrl === url) {
      newUrl = url.replace(/[-_](small|thumbnail|thumb|tm)/, "");
    }

    if (newUrl === url) {
      output.sendDone({ url });
      return;
    }
    // Verify the candidate exists; fall back to the original URL
    fetch(newUrl, { method: "HEAD", redirect: "follow" })
      .then((response) => {
        if (!response.ok) {
          output.sendDone({ url });
          return;
        }
        // Flickr redirects to a photo_unavailable image if the new URL
        // does not exist
        if (
          url.includes("staticflickr.com") &&
          response.url.includes("photo_unavailable")
        ) {
          output.sendDone({ url });
          return;
        }
        output.sendDone({ url: response.url });
      })
      .catch(() => {
        output.sendDone({ url });
      });
  });

  return c;
}
