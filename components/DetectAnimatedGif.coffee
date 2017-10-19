noflo = require 'noflo'
animated = require 'animated-gif-detector'
fs = require 'fs'
# @runtime noflo-nodejs
# @name DetectAnimatedGif

exports.getComponent = ->
  c = new noflo.Component

  c.icon = 'expand'
  c.description = 'Detect if a given GIF is animated'

  c.inPorts.add 'buffer',
    datatype: 'buffer'
    description: 'An image buffer'
  c.outPorts.add 'animated',
    datatype: 'boolean'

  noflo.helpers.WirePattern c,
    in: ['buffer']
    out: ['animated']
    async: true
    forwardGroups: true
  , (buffer, groups, out, callback) ->
    if Buffer.isBuffer buffer
      out.send animated buffer
      do callback
      return
    else if typeof buffer is 'string'
      isAnimated = false
      fs.createReadStream buffer
        .pipe animated()
        .once 'animated', ->
          isAnimated = true
          return
        .on 'finish', ->
          out.send isAnimated
          do callback
          return
      return
    out.send false
    do callback
    return
