noflo = require 'noflo'

if noflo.isBrowser()
  requestAnimationFrame =
    window.requestAnimationFrame       ||
    window.webkitRequestAnimationFrame ||
    window.mozRequestAnimationFrame    ||
    window.oRequestAnimationFrame      ||
    window.msRequestAnimationFrame     ||
    (callback, element) ->
      window.setTimeout( ->
        callback(+new Date())
      , 1000 / 60)

class VideoToCanvas extends noflo.Component
  description: 'Convert video to canvas.'
  icon: 'file-image-o'

  constructor: ->
    @image = null

    @inPorts =
      image: new noflo.Port 'object'
    @outPorts =
      canvas: new noflo.Port 'object'

    @inPorts.image.on 'data', (image) =>
      @image = image
      @videoToCanvas()

  videoToCanvas: ->
    return unless @outPorts.canvas.isAttached()
    return unless @image

    if @image.tagName? and @image.tagName is 'VIDEO'
      requestAnimationFrame @videoToCanvas.bind(@)

    image = @image
    
    if noflo.isBrowser()
      canvas = document.createElement 'canvas'
      canvas.width = image.width
      canvas.height = image.height
    else
      Canvas = require 'canvas'
      canvas = new Canvas image.width, image.height

    context = canvas.getContext '2d'
    context.drawImage image, 0, 0

    @outPorts.canvas.send canvas

exports.getComponent = -> new VideoToCanvas



