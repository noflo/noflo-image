noflo = require 'noflo'
Canvas = require('noflo-canvas').canvas

# @runtime noflo-nodejs
# @name BufferToCanvas

exports.getComponent = ->
  c = new noflo.Component

  c.icon = 'expand'
  c.description = 'Convert a buffer to a canvas'

  c.inPorts.add 'buffer',
    datatype: 'object'
    description: 'An image buffer'
  c.outPorts.add 'canvas',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: ['buffer']
    out: ['canvas']
    async: true
    forwardGroups: true
  , (payload, groups, out, callback) ->
    image = new Canvas.Image
    image.src = payload
    # Create a host canvas and draw on it
    canvas = new Canvas(image.width, image.height)
    ctx = canvas.getContext '2d'
    ctx.drawImage image, 0, 0, image.width, image.height
    out.send canvas
    do callback

  c
