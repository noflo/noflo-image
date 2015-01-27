noflo = require 'noflo'
RgbQuant = require 'rgbquant'

class GetColors extends noflo.Component
  description: 'Extract the dominant colors of an image'
  icon: 'file-image-o'
  constructor: ->

    @outputCssColors = false
    @colors = 10

    @inPorts = new noflo.InPorts
      canvas:
        datatype: 'object'
      css:
        datatype: 'boolean'
      colors:
        datatype: 'number'
        default: 10
      quality:
        description: 'deprecated'
    @outPorts =
      colors: new noflo.Port 'array'
      canvas: new noflo.Port 'object'
      error: new noflo.Port 'object'

    @inPorts.canvas.on 'begingroup', (group) =>
      @outPorts.canvas.beginGroup group
      @outPorts.colors.beginGroup group
    @inPorts.canvas.on 'endgroup', (group) =>
      @outPorts.canvas.endGroup group
      @outPorts.colors.endGroup group
    @inPorts.canvas.on 'disconnect', () =>
      @outPorts.colors.disconnect()
      @outPorts.canvas.disconnect()
    @inPorts.canvas.on 'data', (canvas) =>
      try
        quant = new RgbQuant
          colors: @colors
          method: 1
          initColors: 4096
        # analyze histograms
        quant.sample(canvas)
        # build palette
        outputTuples = true
        noSort = true
        colors = quant.palette outputTuples, noSort
        if @outputCssColors
          colors = colors.map (color) -> "rgb(#{color[0]}, #{color[1]}, #{color[2]})"
      catch e
        @outPorts.canvas.send canvas
        return unless @outPorts.error.isAttached()
        @outPorts.error.send e
        @outPorts.error.disconnect()
        return
      @outPorts.colors.send colors
      @outPorts.canvas.send canvas

    @inPorts.css.on 'data', (boo) =>
      @outputCssColors = boo
    @inPorts.colors.on 'data', (data) =>
      @colors = data
    @inPorts.quality.on 'data', (data) =>
      console.warn 'the quality inport is deprecated'

exports.getComponent = -> new GetColors
