noflo = require 'noflo'

# @runtime noflo-browser
# @name CreateImage

class CreateImage extends noflo.AsyncComponent
  description: 'Loads an image from given url, sends the element'
  icon: 'picture-o'
  constructor: ->
    @inPorts = new noflo.InPorts
      url:
        datatype: 'string'
        type: 'string/url'
    @outPorts = new noflo.OutPorts
      image:
        datatype: 'object'
        type: 'html/element/img'
      error:
        datatype: 'object'
    super 'url', 'image'

  doAsync: (url, callback) ->
    image = new Image()
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
