noflo = require 'noflo'
Canvas = require 'canvas'
Image = Canvas.Image
urlUtil = require 'url'
needle = require 'needle'
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
      resp = needle.get url,
        output: tmpFile.path
        follow: yes
      , (err, response) ->
        if err
          onError err
          tmpFile.unlink()
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
