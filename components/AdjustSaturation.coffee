noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Adjust saturation level of a given image.'
  c.icon = 'file-image-o'

  c.image = null
  c.level = 1.0

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

    level *= -0.01

    for i in [0...data.length] by 4
      max = Math.max data[i], data[i+1], data[i+2]
      data[i] += (max - data[i]) * level if data[i] isnt max
      data[i+1] += (max - data[i+1]) * level if data[i+1] isnt max
      data[i+2] += (max - data[i+2]) * level if data[i+2] isnt max

    ctx.putImageData imageData, 0, 0

    c.outPorts.canvas.send canvas

  c

