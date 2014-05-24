noflo = require 'noflo'

# Create NxM equally spaced points within @bounds
calculateStartingPoints = (bounds, segments) ->
  points = []
  for sx in [1..segments.x]
    for sy in [1..segments.y]
      x = bounds.w*(sx/(segments.x+1))
      y = bounds.h*(sy/(segments.y+1))
      points.push {x: x, y: y}
  return points

# Create sorted array for looking up points by their X and Y coordinates
# Note: no deduplication, two indices may refer to same X or Y coordinate
spatialSortedIndices = (corners) ->
  indices =
    x: [0...corners.length]
    y: [0...corners.length]
  sortByX = (a,b) ->
    return 1 if corners[a].x > corners[b].x
    return -1 if corners[a].x < corners[b].x
    return 0
  sortByY = (a,b) ->
    return 1 if corners[a].y > corners[b].y
    return -1 if corners[a].y < corners[b].y
    return 0
  indices.x.sort sortByX
  indices.y.sort sortByY
  return indices

# Find the index of @point in @indices for given @axis
# Returns -1 if point.axis is smaller than all corners, or corners.length if bigger
findIndexForPoint = (corners, indices, point) ->
  findIndexAxis = (axis) ->
    length = indices[axis].length
    if point[axis] > corners[indices[axis][length-1]][axis]
      return length
    for i in [0...length]
      idx = indices[axis][i]
      if corners[idx][axis] > point[axis]
        return i-1
    return -1
  r =
    x: findIndexAxis 'x'
    y: findIndexAxis 'y'
  return r

# Grow rectangle initially sized 0,0 at @point until @threshold corners have been hit
growRectangle = (corners, indices, point, bounds, threshold) ->
  if point.x > bounds.w or point.y > point.h
    throw new Error "Initial point is outside bounds"

  # Find where point is in our sorted list of corners
  pointIndex = findIndexForPoint corners, indices, point

  coordinateForIndex = (axis, index) ->
    if index < 0
      return 0
    if index >= indices[axis].length
      edge = if axis == 'x' then bounds.w else bounds.h
      return edge
    idx = indices[axis][index]
    p = corners[idx]
    return p[axis]

  # Expand rectangle in all directions
  x0 = coordinateForIndex 'x', pointIndex.x-threshold
  x1 = coordinateForIndex 'x', pointIndex.x+threshold
  y0 = coordinateForIndex 'y', pointIndex.y-threshold
  y1 = coordinateForIndex 'y', pointIndex.y+threshold
  r = { x: x0, y: y0, width: x1-x0, height: y1-y0 }
  return r

findRegions = (corners, bounds) ->
  # TODO: make number of segments configurable?
  # TODO: automatically set Y segments based on image aspect?
  segments = { x: 3, y: 4 }
  threshold = 1
  indices = spatialSortedIndices corners
  regions = []
  for point in calculateStartingPoints bounds, segments
    console.log point
    region = growRectangle corners, point, threshold
    regions.push region
    console.log region

  sortByArea = (a,b) ->
    A = a.width*a.height
    B = b.width*b.height
    return 1 if A > B
    return -1 if A < B
    return 0
  regions.sort sortByArea
  return regions

class FindFeatureFreeAreas extends noflo.Component
  description: 'Extract feature corners of image (method: YAPE)'
  icon: 'file-image-o'
  constructor: ->

    @inPorts =
      corners: new noflo.Port 'array'
      width: new noflo.Port 'int'
      height: new noflo.Port 'int'
      sections: new noflo.Port 'int'
    @outPorts =
      areas: new noflo.Port 'array'
      corners: new noflo.Port 'array'

    @inPorts.corners.on 'begingroup', (group) =>
      @outPorts.corners.beginGroup group
      @outPorts.canvas.beginGroup group
    @inPorts.corners.on 'endgroup', (group) =>
      @outPorts.corners.endGroup group
      @outPorts.canvas.endGroup group
    @inPorts.corners.on 'disconnect', () =>
      @outPorts.corners.disconnect()
      @outPorts.canvas.disconnect()
    @inPorts.corners.on 'data', (corners) =>
      regions = @findRegions corners, {w:1000, h:1000}
      @outPorts.canvas.send regions
      @outPorts.corners.send corners

exports.getComponent = -> new FindFeatureFreeAreas
exports.calculateStartingPoints = calculateStartingPoints
exports.spatialSortedIndices = spatialSortedIndices
exports.findIndexForPoint = findIndexForPoint
exports.growRectangle = growRectangle


