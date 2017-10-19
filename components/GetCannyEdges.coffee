noflo = require 'noflo'
jsfeat = require 'jsfeat'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Canny edge detector.'
  c.icon = 'file-image-o'
  c.inPorts.add 'canvas',
    datatype: 'object'
  c.inPorts.add 'low',
    datatype: 'number'
    control: true
    default: 20
  c.inPorts.add 'high',
    datatype: 'number'
    control: true
    default: 50
  c.inPorts.add 'kernel',
    datatype: 'number'
    control: true
    default: 6
  c.outPorts.add 'canvas',
    datatype: 'object'
  c.forwardBrackets =
    canvas: ['canvas']
  c.process (input, output) ->
    return unless input.hasData 'canvas'
    return if input.attached('low').length and not input.hasData 'low'
    return if input.attached('high').length and not input.hasData 'high'
    return if input.attached('kernel').length and not input.hasData 'kernel'
    low = if input.hasData('low') then input.getData('low') else 20
    high = if input.hasData('high') then input.getData('high') else 50
    kernel = if input.hasData('kernel') then input.getData('kernel') else 6
    canvas = input.getData 'canvas'
    
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

    output.sendDone
      canvas: canvas
    return
