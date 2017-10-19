noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Adjust contrast level of a given image.'
  c.icon = 'file-image-o'
  c.inPorts.add 'canvas',
    datatype: 'object'
  c.inPorts.add 'level',
    datatype: 'number'
    control: true
    default: 1.0
  c.outPorts.add 'canvas',
    datatype: 'object'
  c.forwardBrackets =
    canvas: ['canvas']
  c.process (input, output) ->
    return unless input.hasData 'canvas'
    return if input.attached('level').length and not input.hasData 'level'
    level = 1.0
    if input.hasData 'level'
      level = input.getData 'level'

    canvas = input.getData 'canvas'
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

    output.sendDone
      canvas: canvas
    return
