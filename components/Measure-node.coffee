noflo = require 'noflo'
sizeOf = require 'image-size'
urlUtil = require 'url'
request = require 'request'
temporary = require 'temporary'
fs = require 'fs'

# @runtime noflo-nodejs
# @name Measure

class Measure extends noflo.AsyncComponent
  description: 'Load image from URL or path and get dimensions'
  icon: 'picture-o'
  constructor: ->
    @inPorts =
      url: new noflo.Port 'string'
    @outPorts =
      dimensions: new noflo.Port 'object'
      error: new noflo.Port 'object'
    super 'url', 'dimensions'

  doAsync: (url, callback) ->
    onLoad = (err, dimensions) =>
      if err
        onError err
        return
      @outPorts.dimensions.send dimensions
      callback null

    onError = (err) ->
      err.url = url
      return callback err

    urlOptions = urlUtil.parse url
    if urlOptions.protocol
      # Remote image
      # TODO replace this with custom http/s calls that only get first few bytes
      tmpFile = new temporary.File
      stream = fs.createWriteStream tmpFile.path
      req = request url
      req.pipe stream
      error = null
      req.on 'response', (resp) ->
        return if resp.statusCode is 200
        error = new Error "#{url} responded with #{resp.statusCode}"
        error.url = url
      req.on 'end', ->
        if error
          tmpFile.unlink()
          onError error
          return
        try
          sizeOf tmpFile.path, (err, dimensions) ->
            tmpFile.unlink()
            onLoad err, dimensions
        catch e
          tmpFile.unlink()
          onError e
    else
      # Local image
      sizeOf url, onLoad

exports.getComponent = -> new Measure
