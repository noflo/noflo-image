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
  
  #console.log segments
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

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Extract feature corners of image (method: YAPE)'
  c.icon = 'file-image-o'
  c.inPorts.add 'corners',
    datatype: 'array'
  c.inPorts.add 'width',
    datatype: 'int'
    control: true
    default: 0
  c.inPorts.add 'height',
    datatype: 'int'
    control: true
    default: 0
  c.inPorts.add 'segments',
    datatype: 'int'
    control: true
    default: 4
  c.outPorts.add 'areas',
    datatype: 'array'
  c.outPorts.add 'corners',
    datatype: 'array'
  c.forwardBrackets =
    corners: ['areas', 'corners']
  c.process (input, output) ->
    return unless input.hasData 'corners'
    return if input.attached('width').length and not input.hasData 'width'
    return if input.attached('height').length and not input.hasData 'height'
    return if input.attached('segments').length and not input.hasData 'segments'
    width = 0
    if input.hasData 'width'
      width = parseInt input.getData 'width'
    height = 0
    if input.hasData 'height'
      height = parseInt input.getData 'height'
    segments = 4
    if input.hasData 'segments'
      segments = parseInt input.getData 'segments'

    corners = input.getData 'corners'
    b = { w: width, h: height }
    s = segments
    regions = findRegions corners, b, s
    output.send
      areas: regions
      corners: corners
    output.done()
    return

exports.calculateStartingPoints = calculateStartingPoints
exports.spatialSortedIndices = spatialSortedIndices
exports.findIndexForPoint = findIndexForPoint
exports.growRectangle = growRectangle
