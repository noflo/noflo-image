noflo = require 'noflo'
gm = require 'gm'
fileType = require 'file-type'
readChunk = require 'read-chunk'
temporary = require 'temporary'

# @runtime noflo-nodejs
# @name GetGIFFrame

exports.getComponent = ->
  c = new noflo.Component
  c.icon = 'image'
  c.description = 'Extract a frame of a given GIF filepath'

  c.inPorts.add 'in',
    datatype: 'all'
    description: 'An image filepath'
    required: true
  c.inPorts.add 'frame',
    datatype: 'number'
    description: 'Frame to extract'
    required: false
  c.outPorts.add 'out',
    datatype: 'all'
  c.outPorts.add 'error',
    datatype: 'object'
    required: false

  noflo.helpers.WirePattern c,
    in: 'in'
    params: 'frame'
    out: 'out'
    forwardGroups: true
    async: true
  , (payload, groups, out, callback) ->
    chunk = readChunk payload, 0, 262
    frame = if c.params.frame then c.params.frame else 0
    chunk.then (buffer) ->
      type = fileType buffer
      unless type
        err = new Error 'Unsupported MIME type'
        err.payload = payload
        return callback err
      if type.ext is 'gif'
        tmpFile = new temporary.File
        gm payload
        .selectFrame frame
        .write tmpFile.path, (err) ->
          if err
            tmpFile.unlink()
            err.payload = payload
            return callback err
          out.send tmpFile.path
          do callback
          return
      else
        # Not a GIF, just send the tempfile path along
        out.send payload
        do callback
        return
