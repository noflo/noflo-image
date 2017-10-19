noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Adjust saturation level of a given image.'
  c.icon = 'file-image-o'
  c.inPorts.add 'canvas',
    datatype: 'object'
  c.inPorts.add 'level',
    datatype: 'number'
    control: true
    default: 100.0
  c.outPorts.add 'canvas',
    datatype: 'object'
  c.forwardBrackets =
    canvas: ['canvas']
  c.process (input, output) ->
    return unless input.hasData 'canvas'
    return if input.attached('level').length and not input.hasData 'level'
    level = 100.0
    if input.hasData 'level'
      level = input.getData 'level'

    canvas = input.getData 'canvas'

    ctx = canvas.getContext '2d'
    width = canvas.width
    height = canvas.height

    imageData = ctx.getImageData 0, 0, width, height

    data = imageData.data

    level *= -0.01

    for i in [0...data.length] by 4
      max = Math.max data[i], data[i+1], data[i+2]
      data[i] += (max - data[i]) * level if data[i] isnt max
      data[i+1] += (max - data[i+1]) * level if data[i+1] isnt max
      data[i+2] += (max - data[i+2]) * level if data[i+2] isnt max

    ctx.putImageData imageData, 0, 0

    output.sendDone
      canvas: canvas
    return
