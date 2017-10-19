noflo = require 'noflo'
RgbQuant = require 'rgbquant'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Extract the dominant colors of an image'
  c.icon = 'file-image-o'
  c.inPorts = new noflo.InPorts
    canvas:
      datatype: 'object'
    css:
      datatype: 'boolean'
      default: false
    colors:
      datatype: 'number'
      default: 10
    method:
      datatype: 'int'
      default: 1
      values: [1, 2]
  c.outPorts = new noflo.OutPorts
    colors:
      datatype: 'array'
    canvas:
      datatype: 'array'
    error:
      datatype: 'object'

  noflo.helpers.WirePattern c,
    in: 'canvas'
    out: ['colors', 'canvas']
    params: ['css', 'colors', 'method']
    forwardGroups: yes
    async: yes
  , (data, groups, out, callback) ->
    unless data?.height? > 0 and data?.width? > 0
      return callback new Error "Error when trying to get colors: canvas is undefined."

    c.params.colors = 10 unless c.params.colors?
    c.params.method = 1 unless c.params.method?
    try
      quant = new RgbQuant
        colors: c.params.colors
        method: c.params.method
        initColors: 4096
      # analyze histograms
      quant.sample(data)
      # build palette
      outputTuples = true
      noSort = true
      colors = quant.palette outputTuples, noSort
      if c.params.css
        colors = colors.map (color) -> "rgb(#{color[0]}, #{color[1]}, #{color[2]})"
    catch e
      out.canvas.send data
      out.colors.send []
      console.warn "Error when trying to get colors: #{e} Sending an empty array."
      do callback
      return
    out.canvas.send data
    out.colors.send colors
    do callback
    return
