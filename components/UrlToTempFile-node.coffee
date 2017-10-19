noflo = require 'noflo'
tmp = require 'tmp'
fs = require 'fs'
request = require 'request'
urlUtil = require 'url'
pkg = require '../package.json'
log = require 'graceful-logger'

# @runtime noflo-nodejs
# @name UrlToTempFile

buildUserAgent = ->
  "#{pkg.name}/#{pkg.version} (+#{pkg.repository.url})"

finishStream = (fd, tmpFile, callback) ->
  fs.fsync fd, ->
    try
      fs.stat tmpFile.name, (err, stats) ->
        if err
          tmpFile.removeCallback()
          return callback err
        if stats.size is 0
          tmpFile.removeCallback()
          e = new Error "UrlToTempFile: temporary file has zero size"
          return callback e
        return callback null, tmpFile.name
    catch e
      tmpFile.removeCallback()
      return callback e

fetchDataUrl = (url, callback) ->
  data = url.split(",")[1]
  unless data?
    err = new Error "UrlToTempFile: zero-sized data"
    return callback err
  buffer = new Buffer data, 'base64'
  unless Buffer.byteLength(buffer) > 0
    err = new Error "UrlToTempFile: zero-sized buffer"
    return callback err
  tmpFile = tmp.fileSync()
  fs.writeFile tmpFile.name, buffer, 'base64', (err, data) ->
    if err
      tmpFile.removeCallback()
      return callback err
    return callback null, tmpFile.name

fetchRemoteImage = (url, callback) ->
  tmpFile = tmp.fileSync()
  stream = fs.createWriteStream tmpFile.name

  # Semaphore to avoid double errors
  endByError = false

  # Auxiliary function to handle common cases of errors
  endStream = (error) ->
    return if endByError
    endByError = true
    tmpFile.removeCallback()
    req.abort() if req.abort
    return callback error unless stream.close
    stream.close ->
      return callback error

  req = request
    method: 'GET'
    url: url
    timeout: 30000
    headers:
      'user-agent': buildUserAgent()

  req.on 'response', (resp) ->
    if resp.statusCode is 200
      req.pipe stream
      return
    error = new Error "UrlToTempFile: response status code is #{resp.statusCode}"
    return endStream error
  req.on 'error', (err) ->
    error = new Error "UrlToTempFile: request error code is #{err.code}"
    return endStream error

  stream.on 'error', (err) ->
    return endStream error
  stream.once 'open', (fd) ->
    if fd < 0
      err = new Error "UrlToTempFile: bad temporary file descriptor"
      return endStream err
    stream.once 'finish', ->
      return if endByError
      finishStream fd, tmpFile, (error, data) ->
        return callback error if error
        return callback null, data

fetchLocalImage = (url, callback) ->
  try
    fs.stat url, (err, stats) ->
      if err
        return callback err
      if stats.size is 0
        e = new Error "UrlToTempFile: temporary file has zero size"
        return callback e
      return callback null, url
  catch e
    return callback e

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
    # Auxiliary function to common send-or-fail pattern
    sendOrFail = (err, data) ->
      if err
        err.url = url
        log.err err
        return callback err
      unless data
        error = new "UrlToTempFile: no tmp file was found"
        log.err error
        return callback error
      out.send data
      do callback

    url = payload
    urlOptions = urlUtil.parse url
    if urlOptions.protocol is 'data:'
      fetchDataUrl url, sendOrFail
    else if urlOptions.protocol
      unless urlOptions.protocol in ['http:', 'https:']
        err = new Error "UrlToTempFile: protocol #{urlOptions.protocol} is not allowed"
        return sendOrFail err
      fetchRemoteImage url, sendOrFail
    else
      fetchLocalImage url, sendOrFail
    return
