noflo = require 'noflo'
Canvas = require 'canvas'
Image = Canvas.Image
urlUtil = require 'url'
request = require 'request'
temporary = require 'temporary'
fs = require 'fs'

# @runtime noflo-nodejs
# @name CreateImage

class CreateImage extends noflo.AsyncComponent
  description: 'Load image from URL or path and send node-canvas compatible image'
  icon: 'picture-o'
  constructor: ->
    @inFlight = {}
    @inPorts = new noflo.InPorts
      url:
        datatype: 'string'
        type: 'string/url'
      crossorigin:
        datatype: 'string'
        description: 'not applicable to Node version'
        required: false
    @outPorts = new noflo.OutPorts
      image:
        datatype: 'object'
        type: 'noflo-canvas/image'
      error:
        datatype: 'object'
    super 'url', 'image'

  doAsync: (url, callback) ->
    onLoad = (err, image) =>
      if err
        onError err
        return
      @outPorts.image.beginGroup url
      @outPorts.image.send image
      @outPorts.image.endGroup()
      callback null

    onError = (err) ->
      err.url = url
      return callback err

    loadFile = (path) ->
      fs.stat path, (err, stats) ->
        return onError err if err
        if stats.size is 0
          e = new Error 'Zero-sized image'
          return onError e
        fs.readFile path, (err, image) ->
          if err
            return onError err
          img = new Image
          img.onload = () ->
            onLoad null, img
          img.onerror = (err) ->
            onError err, null
          img.src = image

    urlOptions = urlUtil.parse url
    if urlOptions.protocol
      # Remote image
      tmpFile = new temporary.File
      stream = fs.createWriteStream tmpFile.path
      req = request
        url: url
        timeout: 10000
      req.pipe stream
      error = null
      req.on 'response', (resp) ->
        return if resp.statusCode is 200
        error = new Error "#{url} responded with #{resp.statusCode}"
        error.url = url
      req.on 'error', (err) ->
        err.url = url
        error = err
      req.on 'end', =>
        delete @inFlight[url]
        if error
          tmpFile.unlink()
          onError error
          return
        try
          loadFile tmpFile.path
        catch e
          tmpFile.unlink()
          onError e
      @inFlight[url] = req
    else
      # Local image
      loadFile url

  shutdown: ->
    for url, req of @inFlight
      req.abort()
      delete @inFlight[url]
    @q = []
    @errorGroups = []
    super()

exports.getComponent = -> new CreateImage
