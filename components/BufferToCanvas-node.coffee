noflo = require 'noflo'
Canvas = require('noflo-canvas').canvas

# @runtime noflo-nodejs
# @name BufferToCanvas

exports.getComponent = ->
  c = new noflo.Component

  c.icon = 'expand'
  c.description = 'Convert a buffer to a canvas'

  c.inPorts.add 'buffer',
    datatype: 'buffer'
    description: 'An image buffer'
  c.outPorts.add 'canvas',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: ['buffer']
    out: ['canvas']
    async: true
    forwardGroups: true
  , (payload, groups, out, callback) ->
    image = new Canvas.Image
    image.src = payload
    unless image.width > 0 and image.height > 0
      err = new Error "Failed to convert a buffer to a canvas. Buffer has zero dimensions"
      return callback err
    # Create a host canvas and draw on it
    canvas = new Canvas(image.width, image.height)
    ctx = canvas.getContext '2d'
    ctx.drawImage image, 0, 0, image.width, image.height
    out.send canvas
    do callback
    return
