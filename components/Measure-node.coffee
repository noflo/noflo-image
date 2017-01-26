noflo = require 'noflo'
sizeOf = require 'image-size'
urlUtil = require 'url'
request = require 'request'
tmp = require 'tmp'
fs = require 'fs'

# @runtime noflo-nodejs
# @name Measure

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Load image from URL or path and get dimensions'
  c.icon = 'picture-o'

  c.inPorts.add 'url',
    datatype: 'string'
    description: 'URL to load image'
  c.outPorts.add 'dimensions',
    datatype: 'object'
    description: 'Image dimensions'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: 'url'
    out: 'dimensions'
    forwardGroups: true
    async: true
  , (url, groups, out, callback) ->
    onLoad = (err, dimensions) ->
      if err
        onError err
        return
      out.send dimensions
      do callback
      return

    onError = (err) ->
      err.url = url
      console.log "Error on Measure-node component when loading #{url}."
      return callback err

    urlOptions = urlUtil.parse url
    if urlOptions.protocol
      # Remote image
      # TODO replace this with custom http/s calls that only get first few bytes
      tmpFile = tmp.fileSync()
      stream = fs.createWriteStream tmpFile.name
      req = request url
      req.pipe stream
      error = null
      req.on 'response', (resp) ->
        return if resp.statusCode is 200
        error = new Error "#{url} responded with #{resp.statusCode}"
        error.url = url
      req.on 'end', ->
        if error
          tmpFile.removeCallback()
          onError error
          return
        try
          sizeOf tmpFile.name, (err, dimensions) ->
            tmpFile.removeCallback()
            onLoad err, dimensions
        catch e
          tmpFile.removeCallback()
          onError e
    else
      # Local image
      sizeOf url, onLoad
  c
