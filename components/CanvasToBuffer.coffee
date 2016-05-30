noflo = require 'noflo'

# @runtime noflo-nodejs
# @name CanvasToBuffer

exports.getComponent = ->
  c = new noflo.Component

  c.description = 'Convert a canvas to a buffer'
  c.icon = 'picture-o'

  c.inPorts.add 'canvas',
    datatype: 'object'
    description: 'Canvas to be converted'

  c.outPorts.add 'buffer',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'
    required: false

  noflo.helpers.WirePattern c,
    in: 'canvas'
    out: 'buffer'
    forwardGroups: true
    async: true
  , (canvas, groups, out, callback) ->
    canvas.toBuffer (err, buffer) ->
      console.log 'err', err
      console.log 'buffer', buffer
      if err
        return callback err
      out.send buffer
      do callback

  c
