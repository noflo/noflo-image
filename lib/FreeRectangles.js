// Common font sizes (max font width * line height)
/** @type {Record<string, number>} */
const fontAreas = {
  large: 1280, // 32 * 40
  medium: 384, // 16 * 24
  small: 228, // 12 * 19
};

/** @param {number} x @param {number} y @param {number} xx @param {number} yy */
const area = (x, y, xx, yy) => (xx - x) * (yy - y);

/**
 * Whether every cell in the grid region is marked valid.
 * @param {number[][]} grid
 * @param {number} x
 * @param {number} y
 * @param {number} xx
 * @param {number} yy
 * @returns {boolean}
 */
const allOnes = (grid, x, y, xx, yy) => {
  for (let i = x; i < xx; i += 1) {
    for (let j = y; j < yy; j += 1) {
      if (grid[i][j] === 0) {
        return false;
      }
    }
  }
  return true;
};

/**
 * @param {[number, number]} point
 * @param {number[][]} polygon
 * @returns {boolean}
 */
const pointInPolygon = (point, polygon) => {
  const [x, y] = point;
  let hit = false;
  let i = 0;
  let j = polygon.length - 1;
  while (i < polygon.length) {
    const xi = polygon[i][0];
    const yi = polygon[i][1];
    const xj = polygon[j][0];
    const yj = polygon[j][1];
    const intersect =
      yi > y !== yj > y && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi;
    if (intersect) {
      hit = !hit;
    }
    j = i;
    i += 1;
  }
  return hit;
};

/**
 * @param {number[]} cell [x, y, stepX, stepY]
 * @param {number[][]} polygon
 * @returns {boolean}
 */
const polygonInPolygon = (cell, polygon) => {
  const [x, y, stepX, stepY] = cell;
  /** @type {Array<[number, number]>} */
  const points = [
    [x, y],
    [x + stepX, y],
    [x, y + stepY],
    [x + stepX, y + stepY],
  ];
  for (const point of points) {
    if (pointInPolygon(point, polygon)) {
      return true;
    }
  }
  return false;
};

/**
 * Finds bounding rectangles of the regions outside the given salience
 * polygon, annotated with the font sizes they can fit.
 *
 * The 1.x implementation kept the validity grid in module-level state,
 * which corrupted concurrent activations; the grid is local here.
 *
 * @param {{ width: number, height: number }} canvas
 * @param {number[][]} polygon Salience polygon
 * @param {number} threshold Minimum region area in pixels
 * @param {number} max Maximum number of rectangles to return
 * @returns {Array<{ x: number, y: number, width: number, height: number, text: Record<string, number> }>}
 */
export function findFreeRectangles(canvas, polygon, threshold, max) {
  const { width, height } = canvas;

  // How many rows/cols on the grid
  const n = 30;
  const stepI = Math.ceil(width / n);
  const stepJ = Math.ceil(height / n);

  // Initialize the binary matrix with zeros
  /** @type {number[][]} */
  const validGrid = [];
  for (let i = 0; i < n; i += 1) {
    validGrid[i] = [];
    for (let j = 0; j < n; j += 1) {
      validGrid[i][j] = 0;
    }
  }

  // Create a binary matrix of valid (non-salient) cells
  for (let i = 0; i < n; i += 1) {
    for (let j = 0; j < n; j += 1) {
      if (
        polygonInPolygon([i * stepI, j * stepJ, stepI, stepJ], polygon) ===
        false
      ) {
        validGrid[i][j] = 1;
      }
    }
  }

  // Collect valid cells moving a pivot around the matrix. Select the
  // non-salient regions with areas larger than some threshold.
  /** @type {Array<{ x: number, y: number, width: number, height: number, area: number }>} */
  const validRects = [];
  let pi = 0;
  while (pi < n) {
    let pj = 0;
    while (pj < n) {
      const pivot = [pi, pj];
      let i = pivot[0];
      while (i < n) {
        let j = pivot[1];
        while (j < n) {
          const realArea = area(
            pivot[0] * stepI,
            pivot[1] * stepJ,
            i * stepI,
            j * stepJ,
          );
          if (
            allOnes(validGrid, pivot[0], pivot[1], i, j) &&
            realArea > threshold
          ) {
            validRects.push({
              x: pivot[0],
              y: pivot[1],
              width: i - pivot[0],
              height: j - pivot[1],
              area: realArea,
            });
          }
          j += 1;
        }
        i += 1;
      }
      pj += 1;
    }
    pi += 1;
  }

  if (validRects.length === 0) {
    return [];
  }

  // Sort by area, largest first
  validRects.sort((a, b) => {
    if (a.area > b.area) {
      return -1;
    }
    if (a.area < b.area) {
      return 1;
    }
    return 0;
  });

  const result = [];
  for (let i = 0; i < max && i < validRects.length; i += 1) {
    const validRect = validRects[i];
    result.push({
      x: validRect.x * stepI,
      y: validRect.y * stepJ,
      width: validRect.width * stepI,
      height: validRect.height * stepJ,
      text: {
        large: Math.round(validRect.area / fontAreas.large),
        medium: Math.round(validRect.area / fontAreas.medium),
        small: Math.round(validRect.area / fontAreas.small),
      },
    });
  }
  return result;
}
