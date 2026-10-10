/**
 * Extracts a bounding box with uniform borders removed, according to
 * difference thresholds between neighbouring pixel rows and columns.
 */

/**
 * @param {number[]} array
 * @returns {{ mean: number, max: number }}
 */
const diffBetweenNeighbourPixels = (array) => {
  let count = 0;
  let max = 0;
  let prev = array[0];
  for (const element of array) {
    const diff = Math.abs(element - prev);
    count += diff;
    prev = element;
    if (diff > max) {
      max = diff;
    }
  }
  return { mean: count / array.length, max };
};

/** @param {number[]} array */
const average = (array) => {
  if (array.length === 0) {
    return 0;
  }
  return array.reduce((sum, i) => sum + i, 0) / array.length;
};

/**
 * @param {number[]} array
 * @param {{ mean: number, max: number, avg: number }} threshold
 * @returns {boolean}
 */
const isHomogeneous = (array, threshold) => {
  const diff = diffBetweenNeighbourPixels(array);
  return diff.mean <= threshold.mean && diff.max <= threshold.max;
};

/**
 * @param {number[]} array
 * @param {number[]} prev
 * @param {{ mean: number, max: number, avg: number }} threshold
 * @returns {boolean}
 */
const isBorder = (array, prev, threshold) =>
  Math.abs(average(array) - average(prev)) > threshold.avg;

/**
 * @param {{ width: number, height: number, getContext(mode: "2d"): { getImageData(x: number, y: number, w: number, h: number): { data: Uint8ClampedArray } } }} canvas
 * @param {{ mean?: number, max?: number, avg?: number }} thresholds
 * @returns {{ x: number, y: number, width: number, height: number }}
 */
export function getBorderlessBox(canvas, thresholds = {}) {
  const mean = thresholds.mean ?? 0.1;
  const max = thresholds.max ?? 10;
  const avg = thresholds.avg ?? 10;
  /** @type {{ mean: number, max: number, avg: number }} */
  const threshold = { mean, max, avg };
  const diffPercentual = 0.25;
  const maxPercentualCrop = 0.75;
  const percentualConsideredBorder = 0.05;

  const ctx = canvas.getContext("2d");
  const data = ctx.getImageData(0, 0, canvas.width, canvas.height).data;

  // Convert to grayscale
  /** @type {number[]} */
  const gray = [];
  for (let i = 0; i < data.length; i += 4) {
    gray.push(0.2126 * data[i] + 0.7152 * data[i + 1] + 0.0722 * data[i + 2]);
  }

  /** @type {{ x: number, y: number, width: number, height: number }} */
  const bbox = { x: 0, y: 0, width: canvas.width, height: canvas.height };

  // Iterate through the upper lines
  let prev = gray.slice(0, canvas.width);
  for (let line = canvas.width; line < gray.length; line += canvas.width) {
    const next = gray.slice(line, line + canvas.width);
    if (isHomogeneous(prev, threshold)) {
      bbox.y += 1;
      if (isBorder(prev, next, threshold)) {
        break;
      }
      prev = next;
    } else {
      break;
    }
  }

  // Iterate through the bottom lines
  prev = gray.slice(gray.length - canvas.width, gray.length);
  for (let line = gray.length - canvas.width; line > 0; line -= canvas.width) {
    const next = gray.slice(line - canvas.width, line);
    if (isHomogeneous(prev, threshold)) {
      bbox.height -= 1;
      if (isBorder(prev, next, threshold)) {
        break;
      }
      prev = next;
    } else {
      break;
    }
  }

  // Iterate through the left columns
  prev = [];
  for (let col = 0; col < gray.length; col += canvas.width) {
    prev.push(gray[col]);
  }
  for (let column = 1; column < canvas.width; column += 1) {
    const next = [];
    for (let pos = column; pos < gray.length; pos += canvas.width) {
      next.push(gray[pos]);
    }
    if (isHomogeneous(prev, threshold)) {
      bbox.x += 1;
      if (isBorder(prev, next, threshold)) {
        break;
      }
      prev = next;
    } else {
      break;
    }
  }

  // Iterate through the right columns
  prev = [];
  for (let col = gray.length - 1; col >= 0; col -= canvas.width) {
    prev.push(gray[col]);
  }
  for (let column = 1; column < canvas.width; column += 1) {
    const next = [];
    for (let pos = gray.length - 1 - column; pos >= 0; pos -= canvas.width) {
      next.push(gray[pos]);
    }
    if (isHomogeneous(prev, threshold)) {
      bbox.width -= 1;
      if (isBorder(prev, next, threshold)) {
        break;
      }
      prev = next;
    } else {
      break;
    }
  }

  /** @type {{ x: number, y: number, width: number, height: number }} */
  const croppedBbox = {
    x: 0,
    y: 0,
    width: canvas.width,
    height: canvas.height,
  };

  // Crop if there is not too much difference between top and bottom borders
  if (
    Math.abs(bbox.y - (canvas.height - bbox.height)) <
    Math.max(bbox.y, canvas.height - bbox.height) * diffPercentual
  ) {
    croppedBbox.y = bbox.y;
    croppedBbox.height = bbox.height - croppedBbox.y;
  }

  // Crop if there is not too much difference between left and right borders
  if (
    Math.abs(bbox.x - (canvas.width - bbox.width)) <
    Math.max(bbox.x, canvas.width - bbox.width) * diffPercentual
  ) {
    croppedBbox.x = bbox.x;
    croppedBbox.width = bbox.width - croppedBbox.x;
  }

  // Calculate maximum variation in each direction
  const verticalVariation = Math.max(
    bbox.y,
    canvas.height - croppedBbox.height,
  );
  const horizontalVariation = Math.max(
    bbox.x,
    canvas.width - croppedBbox.width,
  );

  const newLength =
    (croppedBbox.height - croppedBbox.y) * (croppedBbox.width - croppedBbox.x);

  // Do not crop if:
  // - The new image size is low than a certain maxPercentualCrop
  // - There are horizontal AND vertical borders
  // - All the image was cropped
  if (
    newLength < (1 - maxPercentualCrop) * gray.length ||
    (verticalVariation > percentualConsideredBorder * canvas.height &&
      horizontalVariation > percentualConsideredBorder * canvas.width) ||
    croppedBbox.width < 0 ||
    croppedBbox.height < 0
  ) {
    return { x: 0, y: 0, width: canvas.width, height: canvas.height };
  }
  return croppedBbox;
}
