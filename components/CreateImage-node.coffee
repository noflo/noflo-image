noflo = require 'noflo'
Canvas = require('noflo-canvas').canvas
Image = Canvas.Image
urlUtil = require 'url'
request = require 'request'
tmp = require 'tmp'
fs = require 'fs'

# @runtime noflo-nodejs
# @name CreateImage

exports.getComponent = ->
  c = new noflo.Component

  c.description = 'Load image from URL or path and send node-canvas compatible image'
  c.icon = 'picture-o'

  c.inPorts.add 'url',
    datatype: 'string'
    description: 'Image URL'
  c.inPorts.add 'crossorigin',
    datatype: 'string'
    description: 'not applicable to Node version'
    required: false
  c.outPorts.add 'image',
    datatype: 'object'
    description: 'Loaded image'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: 'url'
    params: 'crossorigin'
    out: 'image'
    forwardGroups: true
    async: true
  , (url, groups, out, callback) ->
    onLoad = (err, image) ->
      if err
        onError err
        return
      out.beginGroup url
      out.send image
      out.endGroup()
      do callback
      return

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
    if urlOptions.protocol is 'data:'
      img = new Image
      img.onload = () ->
        onLoad null, img
      img.onerror = (err) ->
        onError err, null
      img.src = url
      return
    if urlOptions.protocol
      # Remote image
      tmpFile = tmp.fileSync()
      stream = fs.createWriteStream tmpFile.name
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
      req.on 'end', ->
        if error
          tmpFile.removeCallback()
          onError error
          return
        try
          loadFile tmpFile.name
        catch e
          tmpFile.removeCallback()
          onError e
      return
    # Local image
    loadFile url
  c
