noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Crop the rectangle out of a given canvas'
  c.icon = 'file-image-o'
  c.inPorts = new noflo.InPorts
    canvas:
      datatype: 'object'
      required: true
    rectangle:
      datatype: 'object'
      description: 'A rectangle to crop out'
      required: true
  c.outPorts = new noflo.OutPorts
    canvas:
      datatype: 'object'

  noflo.helpers.WirePattern c,
    in: ['canvas', 'rectangle']
    out: 'canvas'
    forwardGroups: yes
    async: yes
    group: true
  , (input, groups, out, callback) ->
    originalCanvas = input.canvas
    {x, y, width, height} = input.rectangle
    width = Math.abs originalCanvas.width - x if width > originalCanvas.width
    height = Math.abs originalCanvas.height - y if height > originalCanvas.height
    x = 0 if x < 0
    y = 0 if y < 0

    if noflo.isBrowser()
      newCanvas = document.createElement 'canvas'
      newCanvas.width = width
      newCanvas.height = height
    else
      Canvas = require('noflo-canvas').canvas
      newCanvas = new Canvas width, height

    newCtx = newCanvas.getContext '2d'
    newCtx.drawImage originalCanvas, x, y, width, height, 0, 0, width, height

    if originalCanvas.originalWidth?
      newCanvas.originalWidth = originalCanvas.originalWidth
    if originalCanvas.originalHeight?
      newCanvas.originalHeight = originalCanvas.originalHeight

    out.send newCanvas
    do callback
  c
