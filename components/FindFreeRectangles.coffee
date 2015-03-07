noflo = require 'noflo'

validGrid = []

# Common font sizes (max font width * line height)
fontAreas =
  large: 1280 # 32 * 40
  medium: 384 # 16 * 24
  small: 228 # 12 * 19

area = (x, y, xx, yy) ->
  return (xx-x) * (yy-y)

allOnes = (x, y, xx, yy) ->
  for i in [x...xx]
    for j in [y...yy]
      if validGrid[i][j] == 0
        return false
  true

pointInPolygon = (point, polygon) ->
  x = point[0]
  y = point[1]
  hit = false
  i = 0
  j = polygon.length - 1
  while i < polygon.length
    xi = polygon[i][0]
    yi = polygon[i][1]
    xj = polygon[j][0]
    yj = polygon[j][1]
    intersect = ((yi > y) != (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi)
    if intersect
      hit = not hit
    j = i++
  hit

polygonInPolygon = (polygon, otherPolygon) ->
  x = polygon[0]
  y = polygon[1]
  stepX = polygon[2]
  stepY = polygon[3]
  points = [
    [
      x
      y
    ]
    [
      x + stepX
      y
    ]
    [
      x
      y + stepY
    ]
    [
      x + stepX
      y + stepY
    ]
  ]
  for i in [0...points.length]
    if pointInPolygon(points[i], otherPolygon) is true
      return true
  false

compute = (canvas, polygon, threshold, max) ->
  {width, height} = canvas

  # How many rows/cols on the grid
  n = 30
  stepI = Math.ceil width/n
  stepJ = Math.ceil height/n
  rectangles = []

  # Initialize the binary matrix with zeros
  for i in [0...n]
    validGrid[i] = []
    for j in [0...n]
      validGrid[i][j] = 0

  # Create a binary matrix of valid (non-salient) cells
  for i in [0...n]
    for j in [0...n]
      if polygonInPolygon([i*stepI, j*stepJ, stepI, stepJ], polygon) == false
        validGrid[i][j] = 1
  # Collect valid cells moving a pivot around the matrix. Select the
  # non-salient regions with areas smaller than some threshold.
  validRects = []
  pi = 0
  while pi < n
    pj = 0
    while pj < n
      pivot = [pi, pj]
      i = pivot[0]
      while i < n
        j = pivot[1]
        while j < n
          realArea = area(pivot[0] * stepI, pivot[1] * stepJ, i * stepI, j * stepJ)
          if (allOnes(pivot[0], pivot[1], i, j) == true) and (realArea > threshold)
            validRects.push
              x: pivot[0]
              y: pivot[1]
              width: i - pivot[0]
              height: j - pivot[1]
              area: realArea
          j += 1
        i += 1
      pj += 1
    pi += 1

  if validRects.length is 0
    return []

  # Sort by area
  validRects.sort (a, b) ->
    keyA = a.area
    keyB = b.area
    if keyA > keyB
      return -1
    if keyA < keyB
      return 1
    0

  # We have the rectangles
  result = []
  i = 0
  while i < max
    validRect = validRects[i]
    validArea = validRect.area
    r =
      x: validRect.x * stepI
      y: validRect.y * stepJ
      width: validRect.width * stepI
      height: validRect.height * stepJ
      text:
        large: Math.round validArea / fontAreas.large
        medium: Math.round validArea / fontAreas.medium
        small: Math.round validArea / fontAreas.small
    result.push r
    i += 1

  return result

exports.getComponent = ->
  c = new noflo.Component
  c.icon = 'file-image-o'
  c.description = 'Find bounding rectangles of regions outside of the given polygon.'

  c.outPorts.add 'out',
    datatype: 'array'

  c.inPorts.add 'canvas',
    datatype: 'object'
  c.inPorts.add 'polygon',
    datatype: 'array'
  c.inPorts.add 'threshold',
    datatype: 'number'
    required: yes
  c.inPorts.add 'max',
    datatype: 'number'
    required: yes

  noflo.helpers.WirePattern c,
    in: ['canvas', 'polygon']
    params: ['threshold', 'max']
    out: 'out'
    forwardGroups: true
  , (payload, groups, out, callback) ->
    {canvas, polygon} = payload
    {threshold, max} = c.params

    validRects = compute canvas, polygon, threshold, max

    out.send validRects

  c