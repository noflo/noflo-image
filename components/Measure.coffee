noflo = require 'noflo'

class Measure extends noflo.AsyncComponent
  description: 'Load image from URL and get dimensions'
  icon: 'picture-o'
  constructor: ->
    @inPorts =
      url: new noflo.Port 'string'
    @outPorts =
      dimensions: new noflo.Port 'array'
      error: new noflo.Port 'object'
    super 'url', 'dimensions'
    
  doAsync: (url, callback) ->
    image = new Image()
    image.onload = () =>
      if (image.naturalWidth? and image.naturalWidth is 0) or image.width is 0
        image.onerror()
        return
      dimensions = [image.width, image.height]
      @outPorts.dimensions.beginGroup url
      @outPorts.dimensions.send dimensions
      @outPorts.dimensions.endGroup()
      @outPorts.dimensions.disconnect()
      callback null
    image.onerror = (err) ->
      return callback err
    image.src = url
    null

exports.getComponent = -> new Measure