noflo = require 'noflo'

# @runtime noflo-browser
# @name Measure

exports.getComponent = ->
  c = new noflo.Component

  c.description = 'Load image from URL and get dimensions'
  c.icon = 'picture-o'

  c.inPorts.add 'url',
    datatype: 'string'
    description: 'URL to load image'
  c.outPorts.add 'dimensions',
    datatype: 'object'
    description: 'Image dimensions'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: 'url'
    out: 'dimensions'
    forwardGroups: true
    async: true
  , (url, groups, out, callback) ->
    image = new Image()
    image.onload = () ->
      if (image.naturalWidth? and image.naturalWidth is 0) or image.width is 0
        image.onerror new Error "#{url} didn't come back as a valid image."
        return
      dimensions =
        width: image.width
        height: image.height
      out.beginGroup url
      out.send dimensions
      out.endGroup()
      do callback
    image.onerror = (err) ->
      err.url = url
      return callback err
    image.src = url
  c
