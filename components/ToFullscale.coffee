noflo = require 'noflo'
superagent = require 'superagent'
unless noflo.isBrowser()
  URI = require 'urijs'
else
  URI = require 'URIjs'

convertFlickr = (url) ->
  # See docs in https://www.flickr.com/services/api/misc.urls.html
  format = url.match /_(.)\.(gif|png|jpg)/
  if format
    # We already have the original
    return url if format[1] is 'o'

    # Another format, return large
    return url.replace(/_(.)\.(gif|png|jpg)/, '_b.$2')

  # Non-specified format, return large
  return url.replace(/\.(gif|png|jpg)/, '_b.$1')

convertWordpress = (url) ->
  return url.replace(/\?w=[\d]+/, '')

convertWikimedia = (url) ->
  return url unless url.match /\/commons\/thumb\//
  url.replace /\/commons\/(thumb)\/([0-9])\/([0-9][a-z])\/(.*)[\\\/][^\\\/]*/, '/commons/$2/$3/$4'

# Returns original
convertImgflo = (url) ->
  return url unless url.match /\/graph\//
  uri = URI url
  params = uri.search true
  return url if not params?.input
  return params.input

# Change the size params
# https://en.gravatar.com/site/implement/images/
convertGravatar = (url) ->
  return url unless url.match /\/avatar\//
  newSize = '512'
  parts = URI.parse url
  q = URI.parseQuery parts.query
  q.s = newSize if q.s?
  q.size = newSize if q.size?
  if not (q.s? or q.size)?
    q.size = newSize
  parts.query = URI.buildQuery q
  return URI.build parts

tryFindingFullscale = (url, out, callback) ->
  # Convert
  newUrl = url
  fullUrl = url.replace /[-_](small|thumbnail|thumb|tm)/, ''
  # Verify that it exists
  superagent.head fullUrl
  .end (err, res) ->
    return callback err if err and res.statusCode isnt 404
    newUrl = fullUrl if res and res.statusCode is 200
    out.beginGroup url
    out.send newUrl
    out.endGroup()
    do callback

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Convert an image URL to potential URL of full-scale image'

  c.inPorts.add 'url',
    datatype: 'string'
  c.outPorts.add 'url',
    datatype: 'string'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: 'url'
    out: 'url'
    async: true
    forwardGroups: true
    group: true
  , (url, groups, out, callback) ->
    newUrl = url
    unless url
      return callback new Error 'No image source provided'
    unless typeof url is 'string'
      return callback new Error 'URL is not a string'

    if url.indexOf('staticflickr.com') isnt -1
      newUrl = convertFlickr url, callback

    if url.indexOf('wordpress.com') isnt -1
      newUrl = convertWordpress url, callback

    if url.indexOf('wikimedia.org') isnt -1
      newUrl = convertWikimedia url, callback

    if url.indexOf('imgflo') isnt -1
      newUrl = convertImgflo url, callback

    if url.indexOf('gravatar.com') isnt -1
      newUrl = convertGravatar url, callback

    if url.match /[-_](small|thumb)/
      return tryFindingFullscale url, out, callback

    out.beginGroup url
    out.send newUrl
    out.endGroup()
    do callback

  c
