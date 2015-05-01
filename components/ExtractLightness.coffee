noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.icon = 'file-image-o'
  c.description = 'Extract global lightness of a given image. Light images will return values greater than zero.'

  c.outPorts.add 'lightness',
    datatype: 'number'

  c.inPorts.add 'canvas',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: ['canvas']
    out: ['lightness']
    forwardGroups: true
  , (payload, groups, out) ->
    canvas = payload
    ctx = canvas.getContext '2d'
    imageData = ctx.getImageData 0, 0, canvas.width, canvas.height
    data = imageData.data
    lightPixels = 0
    darkPixels = 0
    # Middle intensity
    threshold = 127

    for i in [0...data.length] by 4
      r = data[i]
      g = data[i+1]
      b = data[i+2]
      max = Math.max(Math.max(r, g), b)
      if max >= threshold
        lightPixels += 1
      else
        darkPixels += 1
    imageArea = canvas.width * canvas.height
    lightness = (lightPixels - darkPixels) / imageArea
    
    out.send lightness

  c
        
