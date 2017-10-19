noflo = require 'noflo'
d3 = require 'd3-color'
# @runtime noflo-nodejs

defaultStep = 1

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

  rgb = d3.rgb(r, g, b)
  # CIE LCH (or popular HCL) and HSL
  lch = d3.hcl(rgb)
  hsl = d3.hsl(rgb)
  h = Math.round(hsl.h)|0
  s = hsl.s*100|0
  l = hsl.l*100|0
  c = Math.round(lch.c)|0
  res.h[h] += 1
  res.s[s] += 1
  res.l[l] += 1
  res.c[c] += 1
  do callback

computeHistogram = (data, res, step=defaultStep, callback) ->
  rgba = 4
  countHistograms = 0
  step = if (data.length < (step * rgba)) or (step < 1) then 1 else step
  pixels = data.length / (rgba * step)
  last = data.length - step * rgba

  for index in [0...data.length] by step * rgba
    addEntryHistogram data, res, index, ->
      if index >= last
        # Normalize such that 1.0 means all pixels have this color
        for histogram of res
          normalize res[histogram], pixels, ->
            countHistograms++
            if countHistograms == (Object.keys res).length
              do callback

exports.getComponent = ->
  c = new noflo.Component
  c.icon = 'file-image-o'
  c.description = 'Calculate RGBAY and HSCL histograms of a given canvas.'

  c.inPorts.add 'canvas',
    datatype: 'object'
  c.inPorts.add 'step',
    datatype: 'number'
  c.outPorts.add 'histogram',
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.WirePattern c,
    in: ['canvas']
    params: ['step']
    out: 'histogram'
    forwardGroups: true
    async: true
  , (payload, groups, out, callback) ->
    canvas = payload
    unless canvas?.width > 0 and canvas?.height > 0
      err = new Error "Failed to compute histogram. Canvas has zero dimensions"
      callback err
      return

    step = if c.params.step? then Math.round c.params.step else defaultStep
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
      c: zero new Array 135 # https://github.com/gka/chroma.js/issues/63
      l: zero new Array 101 # [0.0, 1.0] -> [0, 101]
    computeHistogram imageData.data, result, step, ->
      out.send result
      do callback
    return
