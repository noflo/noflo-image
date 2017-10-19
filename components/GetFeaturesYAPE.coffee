noflo = require 'noflo'
jsfeat = require 'jsfeat'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Extract feature corners of image (method: YAPE)'
  c.icon = 'file-image-o'
  c.inPorts.add 'canvas',
    datatype: 'object'
  c.outPorts.add 'corners',
    datatype: 'array'
  c.outPorts.add 'canvas',
    datatype: 'object'
  c.forwardBrackets =
    canvas: ['canvas', 'corners']
  c.process (input, output) ->
    return unless input.hasData 'canvas'
    canvas = input.getData 'canvas'
    context = canvas.getContext '2d'
    img = context.getImageData 0, 0, canvas.width, canvas.height

    jsfeat.yape06.laplacian_threshold = 30
    jsfeat.yape06.min_eigen_value_threshold = 25

    img_u8 = new jsfeat.matrix_t canvas.width, canvas.height, jsfeat.U8_t|jsfeat.C1_t
    jsfeat.imgproc.grayscale img.data, canvas.width, canvas.height, img_u8
    jsfeat.imgproc.box_blur_gray img_u8, img_u8, 2, 0

    # TODO: write component which can render points onto the image
    corners = []
    pixels = canvas.width*canvas.height
    for i in [0...pixels]
      corners.push new jsfeat.keypoint_t 0,0,0,
    count = jsfeat.yape06.detect img_u8, corners

    output.sendDone
      corners: corners.slice 0, count
      canvas: canvas
    return
