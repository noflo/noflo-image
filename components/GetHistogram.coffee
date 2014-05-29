noflo = require 'noflo'

zero = (a) ->
  for i in [0...a.length]
    a[i] = 0
  return a

computeHistogram = (canvas) ->
  res =
    r: zero new Array 256
    g: zero new Array 256
    b: zero new Array 256

  # TODO: check if individual scanlines is faster
  ctx = canvas.getContext '2d'
  imageData = ctx.getImageData 0, 0, canvas.width, canvas.height
  pixels = imageData.data
  for i in [0...pixels.length] by 4
    [r, g, b] = [pixels[i], pixels[i+1], pixels[i+1]]
    res.r[r]+=1
    res.g[r]+=1
    res.b[b]+=1

  return res

exports.getComponent = ->
  c = new noflo.Component
  c.outPorts.add 'histogram'
  c.inPorts.add 'canvas', (event, payload) ->
    if event is 'begingroup'
      c.outPorts.histogram.beginGroup payload
    if event is 'endgroup'
      c.outPorts.histogram.endGroup payload
    return unless event is 'data'
    c.outPorts.histogram.send computeHistogram payload

  c

