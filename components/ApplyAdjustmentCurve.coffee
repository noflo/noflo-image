noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Apply a RGBA adjustment curve to a given image.'
  c.icon = 'file-image-o'

  c.curve = null
  c.image = null

  c.inPorts.add 'image', (event, payload) ->
    return unless event is 'data'
    c.image = payload
    c.computeFilter()

  c.inPorts.add 'curve', (event, payload) ->
    return unless event is 'data'
    c.curve = payload
    c.computeFilter()

  c.outPorts.add 'canvas'

  c.computeFilter = ->
    return unless c.outPorts.canvas.isAttached()
    return unless c.curve? and c.image?

    # From the original created by TechSlides at http://techslides.com
    # Instagram filter from http://matthewruddy.github.io/jQuery-filter.me
    canvas = document.createElement 'canvas'
    width = canvas.width = c.image.width
    height = canvas.height = c.image.height
    image = c.image
    curve = c.curve

    ctx = canvas.getContext '2d'
    ctx.drawImage image, 0, 0
    imageData = ctx.getImageData 0, 0, width, height
    data = imageData.data

    for i in [0...data.length] by 4
      # Apply the color R, G, B values to each individual pixel
      data[i] = curve.r[data[i]]
      data[i+1] = curve.g[data[i+1]]
      data[i+2] = curve.b[data[i+2]]

      # Apply the overall RGB contrast changes to each pixel
      data[i] = curve.a[data[i]]
      data[i+1] = curve.a[data[i+1]]
      data[i+2] = curve.a[data[i+2]]

    ctx.putImageData imageData, 0, 0

    c.outPorts.canvas.send canvas

  c

