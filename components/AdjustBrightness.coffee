noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Adjust brightness level of a given image.'
  c.icon = 'file-image-o'

  c.canvas = null
  c.level = 10.0

  c.inPorts.add 'canvas', (event, payload) ->
    if event is 'begingroup'
      c.outPorts.canvas.beginGroup payload
    if event is 'endgroup'
      c.outPorts.canvas.endGroup()
    if event is 'disconnect'
      c.outPorts.canvas.disconnect()
    return unless event is 'data'
    c.canvas = payload
    c.computeFilter()

  c.inPorts.add 'level', (event, payload) ->
    return unless event is 'data'
    c.level = payload
    c.computeFilter()

  c.outPorts.add 'canvas'

  c.computeFilter = ->
    return unless c.outPorts.canvas.isAttached()
    return unless c.level? and c.canvas?

    canvas = c.canvas
    level = c.level

    ctx = canvas.getContext '2d'
    width = canvas.width
    height = canvas.height

    imageData = ctx.getImageData 0, 0, width, height

    data = imageData.data

    level = Math.floor 255 * (level / 100)

    for i in [0...data.length] by 4
      # Apply the color R, G, B values to each individual pixel
      data[i] += level
      data[i+1] += level
      data[i+2] += level

    ctx.putImageData imageData, 0, 0

    c.outPorts.canvas.send canvas

  c

