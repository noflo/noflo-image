noflo = require 'noflo'
chroma = require 'chroma-js'

# @runtime noflo-nodejs

zero = (a) ->
  for i in [0...a.length]
    a[i] = 0
  return a

normalize = (a, max, callback) ->
  for i in [0...a.length]
    a[i] = (a[i]/max)
  do callback

# Perceptual brightness
# CIE Y'601. Input: sR'G'B' (gamma) [0.0-1.0]
cie_y601 = (r, g, b) ->
  return 0.299*r + 0.587*g + 0.114*b

addEntryHistogram = (data, res, i, callback) ->
  [r, g, b, a] = [data[i], data[i+1], data[i+2], data[i+3]]
  y = cie_y601 r/255, g/255, b/255
  y = Math.floor y*255
  res.r[r]+=1
  res.g[g]+=1
  res.b[b]+=1
  res.a[a]+=1
  res.y[y]+=1

  rgb = chroma(r, g, b, 'rgb')
  # CIE LCH (or popular HCL) and HSL
  lch = rgb.lch()
  hsl = rgb.hsl()
  h = Math.round hsl[0]
  s = hsl[1]*100|0
  l = hsl[2]*100|0
  c = Math.round lch[1]
  res.h[h] += 1
  res.s[s] += 1
  res.l[l] += 1
  res.c[c] += 1
  do callback

computeHistogram = (data, res, callback) ->
  pixels = data.length/4
  countEntries = 0
  coutHistograms = 0
  for i in [0...data.length] by 4
    addEntryHistogram data, res, i, ->
      countEntries++
      if countEntries == pixels
        # Normalize such that 1.0 means all pixels have this color
        for histogram of res
          normalize res[histogram], pixels, ->
            coutHistograms++
            if coutHistograms == (Object.keys res).length
              do callback

exports.getComponent = ->
  c = new noflo.Component
  c.icon = 'file-image-o'
  c.description = 'Calculate RGBAY and HSCL histograms of a given canvas.'

  c.inPorts.add 'canvas',
    datatype: 'object'
  c.outPorts.add 'histogram',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: ['canvas']
    out: ['histogram', 'error']
    forwardGroups: true
    async: true
  , (payload, groups, outPorts, callback) ->
    canvas = payload
    unless canvas?.width > 0 and canvas?.height > 0
      err = new Error "Failed to compute histogram. Canvas has zero dimensions"
      outPorts.error.send err
      do callback
      return

    ctx = canvas.getContext '2d'
    imageData = ctx.getImageData 0, 0, canvas.width, canvas.height
    result =
      r: zero new Array 256
      g: zero new Array 256
      b: zero new Array 256
      a: zero new Array 256
      y: zero new Array 256
      h: zero new Array 361 # degrees [0,0, 360.0] -> [0, 361]
      s: zero new Array 101 # [0.0, 1.0] -> [0, 101]
      c: zero new Array 101 # ?
      l: zero new Array 101 # [0.0, 1.0] -> [0, 101]
    computeHistogram imageData.data, result, ->
      outPorts.histogram.send result
    do callback
