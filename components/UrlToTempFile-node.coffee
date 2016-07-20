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
      unless data?
        return callback new Error "Zero-sized data from #{url}"
      buffer = new Buffer data, 'base64'
      unless buffer.length > 0
        return callback new Error "Zero-sized buffer from #{url}"
      tmpFile = new temporary.File
      tmpFile.writeFile buffer, 'base64', (error) ->
        return callback error if error
        out.send tmpFile.path
        do callback
        return
    else if urlOptions.protocol
      unless urlOptions.protocol in ['http:', 'https:']
        callback new Error "Images with #{urlOptions.protocol} protocol not allowed"
        return

      console.log 'UrlToTempFile url', url
      # Remote image
      tmpFile = new temporary.File
      stream = fs.createWriteStream tmpFile.path
      req = request
        url: url
        timeout: 30000
        headers:
          'user-agent': buildUserAgent()
      req.pipe stream
      error = null
      req.on 'response', (resp) ->
        console.log 'UrlToTempFile response', resp.statusCode
        return if resp.statusCode is 200
        error = new Error "Error in UrlToTempFile component. #{url} responded with #{resp.statusCode}"
        error.url = url
      req.on 'error', (err) ->
        error = new Error "Error in UrlToTempFile component. Request returned error for #{url}."
        error.url = url
      req.on 'end', ->
        console.log 'UrlToTempFile end'
        if error
          tmpFile.unlink()
          console.log 'UrlToTempFile error', error
          return callback error
        try
          fs.stat tmpFile.path, (err, stats) ->
            if err
              tmpFile.unlink()
              err.url = url
              console.log 'UrlToTempFile error', err
              return callback err
            if stats.size is 0
              e = new Error "Zero-sized temporary image file"
              e.url = url
              tmpFile.unlink()
              console.log 'UrlToTempFile error', e
              return callback e
            console.log 'UrlToTempFile ok', tmpFile.path
            out.send tmpFile.path
            do callback
        catch e
          tmpFile.unlink()
          e.url = url
          console.log "Error in UrlToTempFile component when sending the temporary file."
          return callback e
      return
    else
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
        console.log "Error in UrlToTempFile component when loading local image."
        return callback e
