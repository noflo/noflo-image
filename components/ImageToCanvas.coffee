noflo = require 'noflo'

class ImageToCanvas extends noflo.Component
  description: 'Convert image to canvas.'
  icon: 'file-image-o'

  constructor: ->
    @image = null

    @inPorts =
      image: new noflo.Port 'object'
    @outPorts =
      canvas: new noflo.Port 'object'

    @inPorts.image.on 'data', (image) =>
      @image = image
      @imageToCanvas()

  imageToCanvas: ->
    return unless @outPorts.canvas.isAttached()
    return unless @image

    image = @image
    
    if noflo.isBrowser()
      canvas = document.createElement 'canvas'
      canvas.width = image.width
      canvas.height = image.height
    else
      Canvas = require('noflo-canvas').canvas
      canvas = new Canvas image.width, image.height

    context = canvas.getContext '2d'
    context.drawImage image, 0, 0

    @outPorts.canvas.send canvas

exports.getComponent = -> new ImageToCanvas



