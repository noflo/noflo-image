noflo = require 'noflo'
d3 = require 'd3-color'
# @runtime noflo-nodejs

exports.getComponent = ->
  c = new noflo.Component
  c.icon = 'file-image-o'
  c.description = 'Extract global saturation of a given image. Saturated images will return values greater than zero.'

  c.outPorts.add 'saturation',
    datatype: 'number'

  c.inPorts.add 'canvas',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: ['canvas']
    out: ['saturation']
    forwardGroups: true
    async: true
  , (payload, groups, out, callback) ->
    canvas = payload
    ctx = canvas.getContext '2d'
    imageData = ctx.getImageData 0, 0, canvas.width, canvas.height
    data = imageData.data
    saturatedPixels = 0
    mutedPixels = 0
    # Middle intensity
    threshold = 0.5

    for i in [0...data.length] by 4
      r = data[i]
      g = data[i+1]
      b = data[i+2]
      rgb = d3.rgb(r, g, b)
      hsl = d3.hsl(rgb)
      if hsl.s >= threshold
        saturatedPixels += 1
      else
        mutedPixels += 1
    imageArea = canvas.width * canvas.height
    saturation = (saturatedPixels - mutedPixels) / imageArea

    out.send saturation
    do callback
    return
