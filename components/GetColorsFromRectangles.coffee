noflo = require 'noflo'
RgbQuant = require 'rgbquant'

exports.getComponent = ->
  c = new noflo.Component
  c.icon = 'file-image-o'
  c.description = 'Extract colors from rectangle regions of a canvas.'

  c.outPorts.add 'out',
    datatype: 'array'
  c.outPorts.add 'error',
    datatype: 'object'

  c.inPorts.add 'canvas',
    datatype: 'object'
  c.inPorts.add 'rect',
    datatype: 'array'
  c.inPorts.add 'css',
    datatype: 'boolean'
    required: yes
  c.inPorts.add 'colors',
    datatype: 'number'
    required: yes

  noflo.helpers.WirePattern c,
    in: ['canvas', 'rect']
    params: ['css', 'colors']
    out: ['out', 'error']
    forwardGroups: true
  , (payload, groups, outs, callback) ->
    {canvas, rect} = payload
    {css, colors} = c.params

    # Stiching pieces to 200x200 for now
    if noflo.isBrowser()
      piece = document.createElement 'canvas'
      piece.width = 200
      piece.height = 200
    else
      Canvas = require('noflo-canvas').canvas
      piece = new Canvas 200, 200
    ctx = piece.getContext '2d'

    pieces = []
    for r in rect
      ctx.drawImage canvas, r.x, r.y, r.width, r.height, 0, 0, 200, 200
      pieces.push piece

    try
      outputTuples = true
      noSort = true
      piecesColors = []
      for piece in pieces
        quant = new RgbQuant
          colors: colors
          method: 1
          initColors: 4096
        quant.sample(piece)
        extractedColors = quant.palette outputTuples, noSort
        if css
          extractedColors = extractedColors.map (color) -> "rgb(#{color[0]}, #{color[1]}, #{color[2]})"

        piecesColors.push extractedColors
    catch e
      return unless outs.error.isAttached()
      outs.error.send e
      outs.error.disconnect()
      return

    outs.out.send piecesColors

  c