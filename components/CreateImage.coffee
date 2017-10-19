noflo = require 'noflo'

# @runtime noflo-browser
# @name CreateImage

exports.getComponent = ->
  c = new noflo.Component

  c.description = 'Loads an image from given url, sends the element'
  c.icon = 'picture-o'

  c.inPorts.add 'url',
    datatype: 'string'
    description: 'Image URL'
  c.inPorts.add 'crossorigin',
    datatype: 'string'
    description: 'crossorigin Anonymous for CORS-enabled server'
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
    image = new Image()
    image.crossOrigin = c.params.crossorigin if c.params.crossorigin
    image.onload = () ->
      out.beginGroup url
      out.send image
      out.endGroup()
      do callback
      return
    image.onerror = (err) ->
      err.url = url
      return callback err
    image.src = url
    return
