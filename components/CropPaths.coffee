noflo = require 'noflo'
RgbQuant = require 'rgbquant'

exports.getComponent = ->
  c = new noflo.Component
  c.icon = 'file-image-o'
  c.description = 'Crop paths from canvas.'

  c.outPorts.add 'out',
    datatype: 'array'
  c.outPorts.add 'error',
    datatype: 'object'

  c.inPorts.add 'canvas',
    datatype: 'object'
  c.inPorts.add 'paths',
    datatype: 'array'
  c.inPorts.add 'reverse',
    datatype: 'boolean'
    required: yes

  noflo.helpers.WirePattern c,
    in: ['canvas', 'paths']
    params: ['reverse']
    out: ['out', 'error']
    forwardGroups: true
  , (payload, groups, outs, callback) ->
    {canvas, paths} = payload
    {reverse} = c.params

    if noflo.isBrowser()
      piece = document.createElement 'canvas'
      piece.width = canvas.width
      piece.height = canvas.height
    else
      Canvas = require('noflo-canvas').canvas
      piece = new Canvas canvas.width, canvas.height
    ctx = piece.getContext '2d'
    ctx.drawImage canvas, 0, 0, canvas.width, canvas.height, 0, 0, canvas.width, canvas.height
    if reverse
      ctx.globalCompositeOperation = "xor"
    else
      ctx.globalCompositeOperation = "destination-atop"

    ctx.beginPath()
    for path in paths
      ctx.moveTo path[0].x, path[0].y
      for coord in path.slice(1)
        ctx.lineTo coord.x, coord.y
    ctx.fill()
    ctx.closePath()

    outs.out.send piece

  c
