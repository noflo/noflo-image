noflo = require 'noflo'

zero = (a) ->
  for i in [0...a.length]
    a[i] = 0
  return a

normalize = (a, max) ->
  for i in [0...a.length]
    a[i] = (a[i]/max)
  return a

# Perceptual brightness
# CIE Y'601. Input: sR'G'B' (gamma) [0.0-1.0]
cie_y601 = (r, g, b) ->
  return 0.299*r + 0.587*g + 0.114*b

computeHistogram = (canvas) ->
  res =
    r: zero new Array 256
    g: zero new Array 256
    b: zero new Array 256
    y: zero new Array 256

  # TODO: check if individual scanlines is faster
  ctx = canvas.getContext '2d'
  imageData = ctx.getImageData 0, 0, canvas.width, canvas.height
  data = imageData.data
  for i in [0...data.length] by 4
    [r, g, b] = [data[i], data[i+1], data[i+2]]
    y = cie_y601 r/255, g/255, b/255
    y = Math.floor y*255
    res.r[r]+=1
    res.g[g]+=1
    res.b[b]+=1
    res.y[y]+=1

  # Normalize such that 1.0 means all pixels have this color
  pixels = data.length/4
  normalize res.r, pixels
  normalize res.g, pixels
  normalize res.b, pixels
  normalize res.y, pixels
    
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

