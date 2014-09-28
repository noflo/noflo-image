noflo = require 'noflo'
jsfeat = require 'jsfeat'

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

class GetCannyEdges extends noflo.Component
  description: 'Canny edge detector.'
  icon: 'file-image-o'

  constructor: ->
    @low = 20
    @high = 50
    @kernel = 6
    @image = null

    @inPorts =
      image: new noflo.Port 'object'
      low: new noflo.Port 'number'
      high: new noflo.Port 'number'
      kernel: new noflo.Port 'number'
    @outPorts =
      image: new noflo.Port 'object'

    @inPorts.image.on 'data', (image) =>
      @image = image
      @computeCanny()

    @inPorts.low.on 'data', (low) =>
      @low = low
      @computeCanny()

    @inPorts.high.on 'data', (high) =>
      @high = high
      @computeCanny()

    @inPorts.kernel.on 'data', (kernel) =>
      @kernel = kernel
      @computeCanny()

  computeCanny: ->
    return unless @outPorts.image.isAttached()
    return unless @image

    if @image.tagName? and @image.tagName is 'VIDEO'
      requestAnimationFrame @computeCanny.bind(@)

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

    img = context.getImageData 0, 0, canvas.width, canvas.height

    img_u8 = new jsfeat.matrix_t canvas.width, canvas.height, jsfeat.U8_t|jsfeat.C1_t
    jsfeat.imgproc.grayscale img.data, img_u8.data
    jsfeat.imgproc.gaussian_blur img_u8, img_u8, @kernel, 0
    jsfeat.imgproc.canny img_u8, img_u8, @low, @high

    img_u32 = new Uint32Array img.data.buffer

    alpha = (0xff << 24)
    i = img_u8.cols*img_u8.rows
    pix = 0
    while --i >= 0
      pix = img_u8.data[i]
      img_u32[i] = alpha | (pix << 16) | (pix << 8) | pix

    context.putImageData img, 0, 0

    @outPorts.image.send canvas

exports.getComponent = -> new GetCannyEdges



