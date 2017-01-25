noflo = require 'noflo'
tmp = require 'tmp'
fs = require 'fs'
request = require 'request'
urlUtil = require 'url'
pkg = require '../package.json'
log = require 'graceful-logger'

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
      unless data?
        err = new Error "UrlToTempFile: zero-sized data"
        err.url = url
        log.err err
        return callback err
      buffer = new Buffer data, 'base64'
      unless Buffer.byteLength(buffer) > 0
        err = new Error "UrlToTempFile: zero-sized buffer"
        err.url = url
        log.err err
        return callback err
      tmpFile = tmp.fileSync()
      fs.writeFile tmpFile.name, buffer, 'base64', (err, data) ->
        if err
          err.url = url
          log.err err
          return callback err
        out.send tmpFile.name
        do callback
        return
    else if urlOptions.protocol
      unless urlOptions.protocol in ['http:', 'https:']
        err = new Error "UrlToTempFile: protocol #{urlOptions.protocol} is not allowed"
        err.url = url
        log.err err
        return callback err
      # Remote image
      tmpFile = tmp.fileSync()
      stream = fs.createWriteStream tmpFile.name
      req = request
        method: 'GET'
        url: url
        timeout: 30000
        headers:
          'user-agent': buildUserAgent()
      error = null
      req.on 'response', (resp) ->
        return if resp.statusCode is 200
        error = new Error "UrlToTempFile: response status code is #{resp.statusCode}"
      req.on 'error', (err) ->
        tmpFile.removeCallback()
        if err.code is 'ETIMEDOUT' or err.code is 'ESOCKETTIMEDOUT'
          error = new Error "UrlToTempFile: request timed out with error code #{err.code}"
          error.url = url
          log.err error
          return callback error
        error = new Error "UrlToTempFile: request error code is #{err.code}"
        error.url = url
        log.err error
        return callback error
      req.on 'end', ->
        if error
          tmpFile.removeCallback()
          error.url = url
          log.err error
          return callback error
        try
          fs.stat tmpFile.name, (err, stats) ->
            if err
              tmpFile.removeCallback()
              err.url = url
              log.err err
              return callback err
            if stats.size is 0
              e = new Error "UrlToTempFile: temporary file has zero size"
              e.url = url
              tmpFile.removeCallback()
              log.err e
              return callback e
            out.send tmpFile.name
            do callback
        catch e
          tmpFile.removeCallback()
          e.url = url
          log.err e
          return callback e
      req.pipe stream
      return
    else
      # Local image
      path = url
      try
        fs.stat path, (err, stats) ->
          if err
            err.url = path
            log.err err
            return callback err
          if stats.size is 0
            e = new Error "UrlToTempFile: temporary file has zero size"
            e.url = path
            log.err e
            return callback e
          out.send url
          do callback
      catch e
        e.url = url
        log.err e
        return callback e
