noflo = require 'noflo'

diffBetweenNeighbourPixels = (array) ->
  count = 0
  max = 0
  prev = array[0]

  for element in array
    diff = Math.abs element - prev
    count += diff
    prev = element
    if diff > max
      max = diff

  mean: count / array.length
  max: max

average = (array) ->
  return 0 if array.length is 0
  sum = array.reduce (s,i) -> s += i
  sum / array.length

isHomogeneous = (array, threshold) ->
  diff = diffBetweenNeighbourPixels array
  if diff.mean <= threshold.mean and
  diff.max <= threshold.max
    true
  else
    false

isBorder = (array, prev, threshold) ->
  avg = Math.abs average(array) - average(prev)
  if avg > threshold.avg
    true
  else
    false

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Extract a bounding box with top and bottom borders removed (according to a certain threshold)'
  c.icon = 'file-image-o'
  c.inPorts = new noflo.InPorts
    canvas:
      datatype: 'object'
    mean:
      datatype: 'number'
      description: 'Mean difference between neighbours at same row'
    max:
      datatype: 'number'
      description: 'Maximal difference between neighbours at same row'
    avg:
      datatype: 'number'
      description: 'Average difference between columns\' neighbours'
  c.outPorts = new noflo.OutPorts
    rectangle:
      datatype: 'object'

  noflo.helpers.WirePattern c,
    in: 'canvas'
    params: ['mean', 'max', 'avg']
    out: 'rectangle'
    forwardGroups: yes
    async: yes
  , (canvas, groups, out, callback) ->
    ctx = canvas.getContext '2d'
    imageData = ctx.getImageData 0, 0, canvas.width, canvas.height
    data = imageData.data
    c.params.mean = 0.1 unless c.params.mean
    c.params.max = 10 unless c.params.max
    c.params.avg = 10 unless c.params.avg
    threshold = c.params
    diffPercentual = 0.25
    maxPercentualCrop = 0.75
    percentualConsideredBorder = 0.05

    # Convert to grayscale
    gray = []
    for i in [0...data.length] by 4
      [r, g, b] = [data[i], data[i+1], data[i+2]]
      conversion = 0.2126*r + 0.7152*g + 0.0722*b
      gray.push conversion

    bbox =
      x: 0
      y: 0
      width: canvas.width
      height: canvas.height

    # Iterate through the upper lines
    prev = gray.slice 0, canvas.width
    for line in [canvas.width...gray.length] by canvas.width
      next = gray.slice line, line + canvas.width
      if isHomogeneous prev, threshold
        bbox.y += 1
        if isBorder prev, next, threshold
          break
        prev = next
      else
        break

    # Iterate through the bottom lines
    prev = gray.slice gray.length - canvas.width, gray.length
    for line in [gray.length-canvas.width...0] by -canvas.width
      next = gray.slice line - canvas.width, line
      if isHomogeneous prev, threshold
        bbox.height -= 1
        if isBorder prev, next, threshold
          break
        prev = next
      else
        break

    # Iterate through the left columns
    prev = []
    for col in [0...gray.length] by canvas.width
      prev.push gray[col]
    for column in [1...canvas.width]
      next = []
      for pos in [column...gray.length] by canvas.width
        next.push gray[pos]
      if isHomogeneous prev, threshold
        bbox.x += 1
        if isBorder prev, next, threshold
          break
        prev = next
      else
        break

    # Iterate through the right columns
    prev = []
    for col in [gray.length - 1..0] by -canvas.width
      prev.push gray[col]
    for column in [1...canvas.width]
      next = []
      for pos in [gray.length - 1 - column..0] by -canvas.width
        next.push gray[pos]
      if isHomogeneous prev, threshold
        bbox.width -= 1
        if isBorder prev, next, threshold
          break
        prev = next
      else
        break

    croppedBbox =
      x: 0
      y: 0
      width: canvas.width
      height: canvas.height

    # Crop if there is not too much difference between top and bottom borders
    if (Math.abs bbox.y - (canvas.height - bbox.height)) <
        (Math.max bbox.y, (canvas.height - bbox.height)) * diffPercentual
      croppedBbox.y = bbox.y
      croppedBbox.height = bbox.height - croppedBbox.y

    # Crop if there is not too much difference between left and right borders
    if (Math.abs bbox.x - (canvas.width - bbox.width)) <
        (Math.max bbox.x, (canvas.width - bbox.width)) * diffPercentual
      croppedBbox.x = bbox.x
      croppedBbox.width = bbox.width - croppedBbox.x

    # Calculate maximum variation in each direction
    verticalVariation = Math.max bbox.y, canvas.height - croppedBbox.height
    horizontalVariation = Math.max bbox.x, canvas.width - croppedBbox.width

    newLength = (croppedBbox.height - croppedBbox.y) *
      (croppedBbox.width - croppedBbox.x)

    # Do not crop if:
    # - The new image size is low than a certain maxPercentualCrop
    if (newLength < ((1.0 - maxPercentualCrop) * gray.length)) or
        # - There are horizontal AND vertical borders
        ((verticalVariation > percentualConsideredBorder * canvas.height) and
        (horizontalVariation > percentualConsideredBorder * canvas.width)) or
        # - All the image was cropped
        croppedBbox.width < 0 or croppedBbox.height < 0
      croppedBbox =
        x: 0
        y: 0
        width: canvas.width
        height: canvas.height

    out.send croppedBbox
    do callback
  c
