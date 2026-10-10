/**
 * Feature-free area finding: grows candidate rectangles from an evenly
 * spaced point grid until they hit feature corners, then returns the
 * regions sorted by area (smallest first).
 */

/**
 * Creates NxM equally spaced points within the bounds.
 * @param {{ w: number, h: number }} bounds
 * @param {{ x: number, y: number }} segments
 * @returns {Array<{ x: number, y: number }>}
 */
export function calculateStartingPoints(bounds, segments) {
  /** @type {Array<{ x: number, y: number }>} */
  const points = [];
  for (let sx = 1; sx <= segments.x; sx += 1) {
    for (let sy = 1; sy <= segments.y; sy += 1) {
      points.push({
        x: bounds.w * (sx / (segments.x + 1)),
        y: bounds.h * (sy / (segments.y + 1)),
      });
    }
  }
  return points;
}

/**
 * Creates sorted index arrays for looking up corners by their X and Y
 * coordinates. No deduplication: two indices may refer to the same X or Y
 * coordinate.
 * @param {Array<{ x: number, y: number }>} corners
 * @returns {{ x: number[], y: number[] }}
 */
export function spatialSortedIndices(corners) {
  /** @type {number[]} */
  const x = [];
  /** @type {number[]} */
  const y = [];
  for (let i = 0; i < corners.length; i += 1) {
    x.push(i);
    y.push(i);
  }
  x.sort((a, b) => {
    if (corners[a].x > corners[b].x) {
      return 1;
    }
    if (corners[a].x < corners[b].x) {
      return -1;
    }
    return 0;
  });
  y.sort((a, b) => {
    if (corners[a].y > corners[b].y) {
      return 1;
    }
    if (corners[a].y < corners[b].y) {
      return -1;
    }
    return 0;
  });
  return { x, y };
}

/**
 * Finds the index of the point in the sorted indices for each axis.
 * Returns -1 when the point coordinate is smaller than all corners, or
 * corners.length when bigger.
 * @param {Array<{ x: number, y: number }>} corners
 * @param {{ x: number[], y: number[] }} indices
 * @param {{ x: number, y: number }} point
 * @returns {{ x: number, y: number }}
 */
export function findIndexForPoint(corners, indices, point) {
  /**
   * @param {"x" | "y"} axis
   * @returns {number}
   */
  const findIndexAxis = (axis) => {
    const length = indices[axis].length;
    if (point[axis] > corners[indices[axis][length - 1]][axis]) {
      return length;
    }
    for (let i = 0; i < length; i += 1) {
      const idx = indices[axis][i];
      if (corners[idx][axis] > point[axis]) {
        return i - 1;
      }
    }
    return -1;
  };
  return { x: findIndexAxis("x"), y: findIndexAxis("y") };
}

/**
 * Grows a rectangle, initially sized 0x0 at the point, until further
 * expansion stops hitting corners.
 * @param {Array<{ x: number, y: number }>} corners
 * @param {{ x: number[], y: number[] }} indices
 * @param {{ x: number, y: number }} point
 * @param {{ w: number, h: number }} bounds
 * @returns {{ x: number, y: number, width: number, height: number }}
 */
export function growRectangle(corners, indices, point, bounds) {
  if (point.x > bounds.w || point.y > bounds.h) {
    // The 1.x implementation compared point.y against point.h, which made
    // the y check vacuous; this now checks the bounds on both axes
    throw new Error("Initial point is outside bounds");
  }

  const pointIndex = findIndexForPoint(corners, indices, point);

  /**
   * @param {"x" | "y"} axis
   * @param {number} index
   * @returns {{ x: number, y: number }}
   */
  const coordinateForIndex = (axis, index) => {
    if (index < 0) {
      return { x: 0, y: 0 };
    }
    if (index >= indices[axis].length) {
      return { x: bounds.w, y: bounds.h };
    }
    return corners[indices[axis][index]];
  };

  /**
   * @param {{ x: number, y: number }} p
   * @param {{ x0: number, x1: number, y0: number, y1: number }} rect
   * @returns {boolean}
   */
  const pointInRect = (p, rect) =>
    p.x >= rect.x0 && p.x <= rect.x1 && p.y >= rect.y0 && p.y <= rect.y1;

  /** @type {{ x0: number, x1: number, y0: number, y1: number }} */
  const rect = { x0: point.x, x1: point.x, y0: point.y, y1: point.y };

  const i = { x: pointIndex.x, y: pointIndex.y };
  for (;;) {
    i.x += 1;
    i.y += 1;
    const x = coordinateForIndex("x", i.x);
    const y = coordinateForIndex("y", i.y);
    let expand = false;
    if (!pointInRect(x, rect)) {
      rect.x1 = x.x;
      expand = true;
    }
    if (!pointInRect(y, rect)) {
      rect.y1 = y.y;
      expand = true;
    }
    if (!expand) {
      break;
    }
    if (i.x > indices.x.length) {
      break;
    }
    if (i.y > indices.y.length) {
      break;
    }
  }

  return {
    x: rect.x0,
    y: rect.y0,
    width: rect.x1 - rect.x0,
    height: rect.y1 - rect.y0,
  };
}

/**
 * Finds feature-free regions across the bounds.
 * @param {Array<{ x: number, y: number }>} corners
 * @param {{ w: number, h: number }} bounds
 * @param {number} segments
 * @returns {Array<{ x: number, y: number, width: number, height: number }>}
 */
export function findRegions(corners, bounds, segments) {
  const segmentCounts =
    bounds.w > bounds.h
      ? { x: segments, y: Math.floor(segments * (bounds.w / bounds.h)) }
      : { x: Math.floor(segments * (bounds.h / bounds.w)), y: segments };

  const indices = spatialSortedIndices(corners);
  /** @type {Array<{ x: number, y: number, width: number, height: number }>} */
  const regions = [];
  for (const point of calculateStartingPoints(bounds, segmentCounts)) {
    regions.push(growRectangle(corners, indices, point, bounds));
  }
  regions.sort((a, b) => {
    const areaA = a.width * a.height;
    const areaB = b.width * b.height;
    if (areaA > areaB) {
      return 1;
    }
    if (areaA < areaB) {
      return -1;
    }
    return 0;
  });
  return regions;
}
