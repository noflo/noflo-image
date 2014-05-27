noflo = require 'noflo'

# @runtime noflo-browser
# @name CreateImage

class CreateImage extends noflo.AsyncComponent
  description: 'Loads an image from given url, sends the element'
  icon: 'picture-o'
  constructor: ->
    @crossorigin = null

    @inPorts = new noflo.InPorts
      url:
        datatype: 'string'
        type: 'string/url'
      crossorigin:
        datatype: 'string'
        description: 'crossorigin Anonymous for CORS-enabled server'
        required: false
    @outPorts = new noflo.OutPorts
      image:
        datatype: 'object'
        type: 'html/element/img'
      error:
        datatype: 'object'
    super 'url', 'image'

    @inPorts.crossorigin.on 'data', (data) =>
      @crossorigin = data

  doAsync: (url, callback) ->
    image = new Image()
    if @crossorigin
      image.crossOrigin = @crossorigin
    image.onload = () =>
      @outPorts.image.beginGroup url
      @outPorts.image.send image
      @outPorts.image.endGroup()
      callback null
    image.onerror = (err) ->
      err.url = url
      return callback err
    image.src = url

exports.getComponent = -> new CreateImage
