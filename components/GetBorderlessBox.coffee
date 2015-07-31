noflo = require 'noflo'

differenceBetweenPixels = (array) ->
  count = 0
  prev = array[0]
  max = 0

  for i in [0...array.length]
    diff = Math.abs(array[i] - prev)
    count += diff
    prev = array[i]
    if diff > max
      max = diff

  mean: count/array.length
  max: max

average = (array) ->
  return 0 if array.length is 0
  sum = array.reduce (s,i) -> s += i
  sum / array.length

isBorder = (array, prev) ->
  threshold =
    mean: 0.5
    max: 10
    avg: 30

  diff = differenceBetweenPixels(array)
  avg = Math.abs(average(array) - average(prev))

  if diff.mean <= threshold.mean and
  diff.max <= threshold.max and
  avg <= threshold.avg
    true
  else
    false

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Extract the borderless bounding box of an image'
  c.icon = 'file-image-o'
  c.inPorts = new noflo.InPorts
    canvas:
      datatype: 'object'
  c.outPorts = new noflo.OutPorts
    rectangle:
      datatype: 'object'

  noflo.helpers.WirePattern c,
    in: 'canvas'
    out: 'rectangle'
    forwardGroups: yes
    async: yes
  , (canvas, groups, out, callback) ->
    ctx = canvas.getContext '2d'
    imageData = ctx.getImageData 0, 0, canvas.width, canvas.height
    data = imageData.data
    bbox =
      x: 0
      y: 0
      width: canvas.width
      height: canvas.height

    # conversion to grayscale
    gray = []
    for i in [0...data.length] by 4
      [r, g, b] = [data[i], data[i+1], data[i+2]]
      conversion = 0.2126*r + 0.7152*g + 0.0722*b
      gray.push(conversion)

    # iterates through the upper lines
    prev = gray.slice(0, canvas.width)
    for i in [0...gray.length] by canvas.width
      line = gray.slice(i, i+canvas.width)
      if isBorder(line, prev)
        prev = line
        bbox.y += 1
      else
        break

    # iterates through the bottom lines
    prev = gray.slice(gray.length-canvas.width, gray.length)
    for i in [gray.length...0] by -canvas.width
      line = gray.slice(i-canvas.width, i)
      if isBorder(line, prev)
        prev = line
        bbox.height -= 1
      else
        break

    # iterates through the left columns
    for line in [0...canvas.width]
      column = []
      for col in [line...gray.length] by canvas.width
        column.push(gray[col])
      if line == 0
        prev = column
      if isBorder(column, prev)
        prev = column
        bbox.x += 1
      else
        break

    # iterates through the right columns
    for line in [0...canvas.width]
      column = []
      for col in [gray.length-1-line..0] by -canvas.width
        column.push(gray[col])
      if line == canvas.width
        prev = column
      if isBorder(column, prev)
        prev = column
        bbox.width -= 1
      else
        break

    bbox.height -= bbox.y
    bbox.width -= bbox.x
    out.send bbox
    do callback
  c
