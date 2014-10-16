noflo = require 'noflo'
jsfeat = require 'jsfeat'

class GetCannyEdges extends noflo.Component
  description: 'Canny edge detector.'
  icon: 'file-image-o'

  constructor: ->
    @low = 20
    @high = 50
    @kernel = 6
    @canvas = null

    @inPorts =
      canvas: new noflo.Port 'object'
      low: new noflo.Port 'number'
      high: new noflo.Port 'number'
      kernel: new noflo.Port 'number'
    @outPorts =
      canvas: new noflo.Port 'object'

    @inPorts.canvas.on 'data', (canvas) =>
      @canvas = canvas
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
    return unless @outPorts.canvas.isAttached()
    return unless @canvas?

    canvas = @canvas
    
    context = canvas.getContext '2d'
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

    @outPorts.canvas.send canvas

exports.getComponent = -> new GetCannyEdges



