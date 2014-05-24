noflo = require 'noflo'
jsfeat = require 'jsfeat'

class GetFeaturesYAPE extends noflo.Component
  description: 'Extract feature corners of image (method: YAPE)'
  icon: 'file-image-o'
  constructor: ->

    @inPorts =
      canvas: new noflo.Port 'object'
    @outPorts =
      corners: new noflo.Port 'array'
      canvas: new noflo.Port 'object'

    @inPorts.canvas.on 'begingroup', (group) =>
      @outPorts.corners.beginGroup group
      @outPorts.canvas.beginGroup group
    @inPorts.canvas.on 'endgroup', (group) =>
      @outPorts.corners.endGroup group
      @outPorts.canvas.endGroup group
    @inPorts.canvas.on 'disconnect', () =>
      @outPorts.corners.disconnect()
      @outPorts.canvas.disconnect()
    @inPorts.canvas.on 'data', (canvas) =>
      corners = @getCorners canvas
      @outPorts.corners.send corners
      @outPorts.canvas.send canvas

  getCorners: (canvas) ->
    context = canvas.getContext '2d'
    img = context.getImageData 0, 0, canvas.width, canvas.height

    jsfeat.yape06.laplacian_threshold = 30
    jsfeat.yape06.min_eigen_value_threshold = 25

    img_u8 = new jsfeat.matrix_t canvas.width, canvas.height, jsfeat.U8_t|jsfeat.C1_t
    jsfeat.imgproc.grayscale img.data, img_u8.data
    jsfeat.imgproc.box_blur_gray img_u8, img_u8, 2, 0

    # TODO: write component which can render points onto the image
    corners = []
    pixels = canvas.width*canvas.height
    for i in [0...pixels]
      corners.push new jsfeat.point2d_t 0,0,0,
    count = jsfeat.yape06.detect img_u8, corners
    return corners.slice 0, count

exports.getComponent = -> new GetFeaturesYAPE



