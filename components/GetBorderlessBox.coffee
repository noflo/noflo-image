noflo = require 'noflo'

difference = (array) ->
  count = 0
  prev = array[0]

  for i in [0...array.length]
    count += Math.abs(array[i] - prev)
    prev = array[i]

  return count/array.length

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

    threshold = 0

    # iterates through the upper lines
    for i in [0...gray.length] by canvas.width
      line = gray.slice(i, i+canvas.width)
      diff = difference(line)
      if diff <= threshold
        bbox.y += 1
      else
        break

    # iterates through the bottom lines
    for i in [gray.length...0] by -canvas.width
      line = gray.slice(i-canvas.width, i)
      diff = difference(line)
      if diff <= threshold
        bbox.height -= 1
      else
        break

    # iterates through the left columns
    for l in [0...canvas.width]
      column = []
      for c in [l...gray.length] by canvas.height
        x = c % canvas.width
        y = (c - x) / canvas.width
        # console.log x, y, c
        column.push(gray[c])

      diff = difference(column)
      # console.log column
      # console.log diff
      if diff <= threshold
        bbox.x += 1
      else
        break

    # iterates through the right columns
    for l in [canvas.width...0] by -1
      column = []
      for c in [gray.length...l] by -canvas.height
        x = c % canvas.width
        y = (c - x) / canvas.width
        column.push(gray[c])

      diff = difference(column)
      if diff <= threshold
        bbox.width -= 1
      else
        break

    out.send bbox
    do callback
  c
