noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Adjust contrast level of a given image.'
  c.icon = 'file-image-o'

  c.image = null
  c.level = 1

  c.inPorts.add 'image', (event, payload) ->
    return unless event is 'data'
    c.image = payload
    c.computeFilter()

  c.inPorts.add 'level', (event, payload) ->
    return unless event is 'data'
    c.level = payload
    c.computeFilter()

  c.outPorts.add 'canvas'

  c.computeFilter = ->
    return unless c.outPorts.canvas.isAttached()
    return unless c.level? and c.image?

    canvas = document.createElement 'canvas'
    width = canvas.width = c.image.width
    height = canvas.height = c.image.height
    image = c.image
    level = c.level

    ctx = canvas.getContext '2d'
    ctx.drawImage image, 0, 0
    imageData = ctx.getImageData 0, 0, width, height
    data = imageData.data

    level = (parseFloat(level) or 0) + 1
 
    for i in [0...data.length] by 4
      data[i] = ((((data[i] / 255) - 0.5) * level) + 0.5) * 255
      data[i+1] = ((((data[i+1] / 255) - 0.5) * level) + 0.5) * 255
      data[i+2] = ((((data[i+2] / 255) - 0.5) * level) + 0.5) * 255

    ctx.putImageData imageData, 0, 0

    c.outPorts.canvas.send canvas

  c

