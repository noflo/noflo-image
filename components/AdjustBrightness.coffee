noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Adjust brightness level of a given image.'
  c.icon = 'file-image-o'
  c.inPorts.add 'canvas',
    datatype: 'object'
  c.inPorts.add 'level',
    datatype: 'number'
    control: true
    default: 10.0
  c.outPorts.add 'canvas',
    datatype: 'object'
  c.forwardBrackets =
    canvas: ['canvas']
  c.process (input, output) ->
    return unless input.hasData 'canvas'
    return if input.attached('level').length and not input.hasData 'level'
    level = 10.0
    if input.hasData 'level'
      level = input.getData 'level'

    canvas = input.getData 'canvas'
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

    output.sendDone
      canvas: canvas
    return
