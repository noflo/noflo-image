noflo = require 'noflo'
animated = require 'animated-gif-detector'

# @runtime noflo-nodejs
# @name DetectAnimatedGif

exports.getComponent = ->
  c = new noflo.Component

  c.icon = 'expand'
  c.description = 'Detect if a given GIF is animated'

  c.inPorts.add 'buffer',
    datatype: 'object'
    description: 'An image buffer'
  c.outPorts.add 'animated',
    datatype: 'boolean'

  noflo.helpers.WirePattern c,
    in: ['buffer']
    out: ['animated']
    async: true
    forwardGroups: true
  , (buffer, groups, out, callback) ->
    out.send animated buffer
    do callback

  c
