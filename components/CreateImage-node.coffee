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
      fs.readFile path, (err, image) ->
        if err
          return onError err
        img = new Image
        img.src = image
        onLoad(null, img)

    urlOptions = urlUtil.parse url
    if urlOptions.protocol
      # Remote image
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
          loadFile tmpFile.path
        catch e
          tmpFile.unlink()
          onError e
    else
      # Local image
      loadFile url

exports.getComponent = -> new CreateImage
