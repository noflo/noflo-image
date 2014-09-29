noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Adjust brightness level of a given image.'
  c.icon = 'file-image-o'

  c.image = null
  c.level = 0

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

    level = Math.floor 255 * (level / 100)

    for i in [0...data.length] by 4
      # Apply the color R, G, B values to each individual pixel
      data[i] += level
      data[i+1] += level
      data[i+2] += level

    ctx.putImageData imageData, 0, 0

    c.outPorts.canvas.send canvas

  c

