noflo = require 'noflo'

# Recursive function for calculating greatest common divisor
gcd = (a, b) -> (if (b is 0) then a else gcd(b, a % b))

exports.getComponent = ->
  c = new noflo.Component
  c.icon = 'file-image-o'
  c.description = 'Calculate aspect ratio from image dimensions'

  c.inPorts.add 'dimensions',
    datatype: 'object'

  c.outPorts.add 'ratio',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: 'dimensions'
    out: 'ratio'
    forwardGroups: true
    async: true
  , (packet, groups, out, callback) ->
    return callback new Error "Dimension is missing width" unless packet.width
    return callback new Error "Dimension is missing height" unless packet.height
    divisor = gcd packet.width, packet.height
    numerator = packet.width / divisor
    denominator = packet.height / divisor
    out.send
      ratio: "#{numerator}:#{denominator}"
      aspect: numerator / denominator
    do callback

  c
