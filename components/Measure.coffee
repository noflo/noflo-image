noflo = require 'noflo'

# @runtime noflo-browser

class Measure extends noflo.AsyncComponent
  description: 'Load image from URL and get dimensions'
  icon: 'picture-o'
  constructor: ->
    @inPorts =
      url: new noflo.Port 'string'
    @outPorts =
      dimensions: new noflo.Port 'object'
      error: new noflo.Port 'object'
    super 'url', 'dimensions'

  doAsync: (url, callback) ->
    image = new Image()
    image.onload = () =>
      if (image.naturalWidth? and image.naturalWidth is 0) or image.width is 0
        image.onerror new Error "#{url} didn't come back as a valid image."
        return
      dimensions =
        width: image.width
        height: image.height
      @outPorts.dimensions.beginGroup url
      @outPorts.dimensions.send dimensions
      @outPorts.dimensions.endGroup()
      callback null
    image.onerror = (err) ->
      err.url = url
      return callback err
    image.src = url

exports.getComponent = -> new Measure
