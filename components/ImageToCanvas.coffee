noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Convert image to canvas.'
  c.icon = 'file-image-o'
  c.inPorts.add 'image',
    datatype: 'object'
  c.outPorts.add 'canvas',
    datatype: 'object'
  c.forwardBrackets =
    image: ['canvas']
  c.process (input, output) ->
    return unless input.hasData 'image'
    image = input.getData 'image'
    
    if noflo.isBrowser()
      canvas = document.createElement 'canvas'
      canvas.width = image.width
      canvas.height = image.height
    else
      Canvas = require('noflo-canvas').canvas
      canvas = new Canvas image.width, image.height

    context = canvas.getContext '2d'
    context.drawImage image, 0, 0

    output.sendDone
      canvas: canvas
    return
