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
      return { x: 0, y: 0 }
    if index >= indices[axis].length
      return { x: bounds.w, y: bounds.h }
    idx = indices[axis][index]
    p = corners[idx]
    return p

  pointInRect = (p, rect) ->
    in_x = p.x >= rect.x0 and p.x <= rect.x1
    in_y = p.y >= rect.y0 and p.y <= rect.y1
    #console.log in_x, in_y
    return in_x and in_y

  r = { x0: point.x, x1: point.x, y0: point.y, y1: point.y }
  
  # Expand
  i = {x: pointIndex.x, y: pointIndex.y}
  while true
    i.x=i.x+1
    i.y=i.y+1
    x = coordinateForIndex 'x', i.x
    y = coordinateForIndex 'y', i.y
    expand = false
    if not pointInRect x, r
      #console.log 'expanding X', x, r
      r.x1 = x.x
      #if x.y > r.y1
        #r.y1 = x.y # TEMP: needed?
      expand = true
    if not pointInRect y, r
      #console.log 'expanding Y', y, r
      r.y1 = y.y
      #if y.x > r.x1
#        r.x1 = y.x
      expand = true
    break if not expand
    break if i.x > indices.x.length
    break if i.y > indices.y.length

#  console.log 'One phase done!'
  ###
  # Expand lower right
  i = {x: pointIndex.x, y: pointIndex.y}
  while true
    i.x=i.x-1
    x = coordinateForIndex 'x', i.x
    expand = false
    console.log i.x, 0, x
    if not pointInRect x, r
      r.x0 = x.x
      expand = true
    i.y=i.y-1
    y = coordinateForIndex 'y', i.y
    console.log i.y, 0, y
    if not pointInRect y, r
      r.y0 = y.y
      expand = true
    break if not expand
    break if i.x < 0
    break if i.y < 0
  ###
  r = { x: r.x0, y: r.y0, width: r.x1-r.x0, height: r.y1-r.y0 }
#  console.log r
  return r

findRegions = (corners, bounds, seg) ->
  if bounds.w > bounds.h
    segments = { x: seg, y: Math.floor(seg*(bounds.w/bounds.h)) }
  else
    segments = { x: Math.floor(seg*(bounds.h/bounds.w)), y: seg }
  
  console.log segments
  threshold = 1
  indices = spatialSortedIndices corners

  regions = []
  for point in calculateStartingPoints bounds, segments
    region = growRectangle corners, indices, point, bounds, threshold
    regions.push region

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
    @width = 0
    @height = 0
    @segments = 4

    @inPorts =
      corners: new noflo.Port 'array'
      width: new noflo.Port 'int'
      height: new noflo.Port 'int'
      segments: new noflo.Port 'int'
    @outPorts =
      areas: new noflo.Port 'array'
      corners: new noflo.Port 'array'

    @inPorts.width.on 'data', (data) =>
      console.log 'width', data
      @width = data
    @inPorts.height.on 'data', (data) =>
      console.log 'height', data
      @height = data
    @inPorts.segments.on 'data', (data) =>
      console.log 'segments', data
      @segments = data

    @inPorts.corners.on 'begingroup', (group) =>
      @outPorts.areas.beginGroup group
      @outPorts.corners.beginGroup group
    @inPorts.corners.on 'endgroup', (group) =>
      @outPorts.areas.endGroup group
      @outPorts.corners.endGroup group
    @inPorts.corners.on 'disconnect', () =>
      @outPorts.areas.disconnect()
      @outPorts.corners.disconnect()
    @inPorts.corners.on 'data', (corners) =>
      b = { w: @width, h: @height }
      s = @segments
      console.log b, s
      regions = findRegions corners, b, s
      @outPorts.areas.send regions
      @outPorts.corners.send corners

exports.getComponent = -> new FindFeatureFreeAreas
exports.calculateStartingPoints = calculateStartingPoints
exports.spatialSortedIndices = spatialSortedIndices
exports.findIndexForPoint = findIndexForPoint
exports.growRectangle = growRectangle


