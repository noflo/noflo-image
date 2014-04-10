noflo = require 'noflo'
sizeOf = require 'image-size'
urlUtil = require 'url'
needle = require 'needle'
temporary = require 'temporary'

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
      @outPorts.dimensions.beginGroup url
      @outPorts.dimensions.send dimensions
      @outPorts.dimensions.endGroup()
      callback null

    onError = (err) ->
      err.url = url
      return callback err

    urlOptions = urlUtil.parse url
    if urlOptions.protocol
      # Remote image
      # TODO replace this with custom http/s calls that only get first few bytes
      tmpFile = new temporary.File
      resp = needle.get url,
        output: tmpFile.path
        follow: yes
      , (err, response) ->
        if err
          onError err
          tmpFile.unlink()
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
