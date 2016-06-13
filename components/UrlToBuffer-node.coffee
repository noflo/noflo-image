noflo = require 'noflo'
temporary = require 'temporary'
fs = require 'fs'
request = require 'request'
urlUtil = require 'url'
pkg = require '../package.json'

# @runtime noflo-nodejs
# @name UrlToBuffer

buildUserAgent = ->
  "#{pkg.name}/#{pkg.version} (+#{pkg.repository.url})"

exports.getComponent = ->
  c = new noflo.Component

  c.description = 'Load image from URL and output a buffer.'
  c.icon = 'picture-o'

  c.inPorts.add 'url',
    datatype: 'string'
    description: 'URL to image file'

  c.outPorts.add 'buffer',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'
    required: false

  noflo.helpers.WirePattern c,
    in: 'url'
    out: 'buffer'
    forwardGroups: true
    async: true
  , (payload, groups, out, callback) ->
    url = payload
    urlOptions = urlUtil.parse url
    if urlOptions.protocol is 'data:'
      # Data URL
      data = url.split(",")[1]
      buffer = new Buffer data, 'base64'
      out.beginGroup url
      out.send buffer
      out.endGroup()
      do callback
      return
    if urlOptions.protocol
      # Remote image
      req = request
        url: url
        timeout: 10000
        headers:
          'user-agent': buildUserAgent()
      bufs = []
      error = null
      req.on 'data', (data) ->
        bufs.push data
      req.on 'response', (resp) ->
        return if resp.statusCode is 200
        error = new Error "#{url} responded with #{resp.statusCode}"
        error.url = url
      req.on 'error', (err) ->
        err.url = url
        error = err
      req.on 'end', ->
        if error
          console.log "Error in UrlToBuffer component on request."
          return callback error
        try
          buffer = Buffer.concat bufs
          out.beginGroup url
          out.send buffer
          out.endGroup()
          do callback
        catch e
          # tmpFile.unlink()
          e.url = url
          console.log "Error in UrlToBuffer component when sending the buffer."
          return callback e
      return

    # Local image
    path = url
    try
      fs.stat path, (err, stats) ->
        return callback err if err
        if stats.size is 0
          e = new Error "Zero-sized local image file"
          e.url = path
          return callback e
        buffer = fs.readFile path, (err, data) ->
          out.beginGroup url
          out.send data
          out.endGroup()
          do callback
    catch e
      e.url = url
      console.log "Error in UrlToBuffer component when loading local image."
      return callback e

  c
