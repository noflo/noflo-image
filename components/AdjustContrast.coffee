noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Adjust contrast level of a given image.'
  c.icon = 'file-image-o'

  c.canvas = null
  c.level = 1.0

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

    level = (parseFloat(level) or 0) + 1.0
 
    for i in [0...data.length] by 4
      data[i] = ((((data[i] / 255) - 0.5) * level) + 0.5) * 255
      data[i+1] = ((((data[i+1] / 255) - 0.5) * level) + 0.5) * 255
      data[i+2] = ((((data[i+2] / 255) - 0.5) * level) + 0.5) * 255

    ctx.putImageData imageData, 0, 0

    c.outPorts.canvas.send canvas

  c

