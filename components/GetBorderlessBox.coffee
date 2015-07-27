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
    threshold = data.length*5
    bbox =
      x: 0
      y: 0
      width: data.width
      height: data.height

    # conversion to grayscale
    gray = []
    for i in [0...data.length] by 4
      [r, g, b] = [data[i], data[i+1], data[i+2]]
      conversion = 0.2126*r + 0.7152*g + 0.0722*b
      gray.push(conversion)

    # iterates through the upper lines
    for i in [0...gray.length] by gray.width
      line = gray.slice(i, i+gray.width)
      diff = difference(line)
      if diff < threshold
        bbox.y += 1
      else
        break

    # iterates through the bottom lines
    for i in [gray.length...0] by gray.width
      line = gray.slice(i-gray.width, i)
      diff = difference(line)
      if diff < threshold
        bbox.height -= 1
      else
        break

    # iterates through the left columns
    for i in [0...gray.width] by gray.length
      line = gray.slice(i, i+gray.length)
      diff = difference(line)
      if diff < threshold
        bbox.x += 1
      else
        break

    # iterates through the right columns
    for i in [gray.width...0] by gray.length
      line = gray.slice(i-gray.length, i)
      diff = difference(line)
      if diff < threshold
        bbox.x += 1
      else
        break

    out.send bbox
    do callback
  c
