noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Apply a vignette effect to a given image.'
  c.icon = 'file-image-o'
  c.inPorts.add 'canvas',
    datatype: 'object'
  c.outPorts.add 'canvas',
    datatype: 'object'
  c.forwardBrackets =
    canvas: ['canvas']
  c.process (input, output) ->
    return unless input.hasData 'canvas'
    canvas = input.getData 'canvas'

    ctx = canvas.getContext '2d'
    width = canvas.width
    height = canvas.height

    imageData = ctx.getImageData 0, 0, width, height

    data = imageData.data

    outerRadius = Math.sqrt(Math.pow(width/2, 2) + Math.pow(height/2, 2))

    # Adds outer darkened blur effect
    ctx.globalCompositeOperation = 'source-over'
    gradient = ctx.createRadialGradient width/2, height/2, 0, width/2, height/2, outerRadius
    gradient.addColorStop 0, 'rgba(0, 0, 0, 0)'
    gradient.addColorStop 0.65, 'rgba(0, 0, 0, 0)'
    gradient.addColorStop 1, 'rgba(0, 0, 0, 0.9)'
    ctx.fillStyle = gradient
    ctx.fillRect 0, 0, width, height

    # Adds central lighten effect
    ctx.globalCompositeOperation = 'lighter'
    gradient = ctx.createRadialGradient width/2, height/2, 0, width/2, height/2, outerRadius
    gradient.addColorStop 0, 'rgba(255, 255, 255, 0.1)'
    gradient.addColorStop 0.65, 'rgba(255, 255, 255, 0)'
    gradient.addColorStop 1, 'rgba(0, 0, 0, 0)'
    ctx.fillStyle = gradient
    ctx.fillRect 0, 0, width, height

    output.sendDone
      canvas: canvas
    return
