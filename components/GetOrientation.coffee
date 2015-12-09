noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.icon = 'file-image-o'
  c.description = 'Get orientation from image dimensions'

  c.inPorts.add 'dimensions',
    datatype: 'object'

  c.outPorts.add 'orientation',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: 'dimensions'
    out: 'orientation'
    forwardGroups: true
    async: true
  , (packet, groups, out, callback) ->
    return callback new Error "Dimension is missing width" unless packet.width
    return callback new Error "Dimension is missing height" unless packet.height
    orientation = 'square'
    if packet.width > packet.height
      orientation = 'landscape'
    if packet.width < packet.height
      orientation = 'portrait'
    out.send
      orientation: orientation
    do callback

  c
