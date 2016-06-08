noflo = require 'noflo'
temporary = require 'temporary'
fs = require 'fs'
request = require 'request'
urlUtil = require 'url'
pkg = require '../package.json'

buildUserAgent = ->
  "#{pkg.name}/#{pkg.version} (+#{pkg.repository.url})"

# @runtime noflo-nodejs
# @name UrlToTempFile

exports.getComponent = ->
  c = new noflo.Component

  c.description = 'Load image from URL and write it to a temporary file.'
  c.icon = 'picture-o'

  c.inPorts.add 'url',
    datatype: 'string'
    description: 'URL to image file'

  c.outPorts.add 'tempfile',
    datatype: 'string'
  c.outPorts.add 'error',
    datatype: 'object'
    required: false

  noflo.helpers.WirePattern c,
    in: 'url'
    out: 'tempfile'
    forwardGroups: true
    async: true
  , (payload, groups, out, callback) ->
    url = payload
    urlOptions = urlUtil.parse url
    if urlOptions.protocol is 'data:'
      # Data URL
      data = url.split(",")[1]
      buffer = new Buffer data, 'base64'
      tmpFile = new temporary.File
      tmpFile.writeFileSync buffer, 'base64'
      out.send tmpFile.path
      do callback
      return
    if urlOptions.protocol
      unless urlOptions.protocol in ['http:', 'https:']
        callback new Error "Images with #{urlOptions.protocol} protocol not allowed"
        return

      # Remote image
      tmpFile = new temporary.File
      stream = fs.createWriteStream tmpFile.path
      req = request
        url: url
        timeout: 10000
        headers:
          'user-agent': buildUserAgent()
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
          tmpFile.unlink()
          return callback error
        try
          fs.stat tmpFile.path, (err, stats) ->
            if err
              tmpFile.unlink()
              err.url = url
              return callback err
            if stats.size is 0
              e = new Error "Zero-sized temporary image file"
              e.url = url
              tmpFile.unlink()
              return callback e
            out.send tmpFile.path
            do callback
        catch e
          tmpFile.unlink()
          e.url = url
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
        out.send url
        do callback
    catch e
      e.url = url
      return callback e

  c
