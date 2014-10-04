noflo = require 'noflo'
ColorThief = require 'color-thief'

class GetColors extends noflo.Component
  description: 'Extract the dominant colors of an image'
  icon: 'file-image-o'
  constructor: ->

    @outputCssColors = false
    @quality = 10
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
        datatype: 'number'
        default: 10
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
      thief = new ColorThief
      context = canvas.getContext '2d'
      pixels = context.getImageData(0, 0, canvas.width, canvas.height).data
      pixelCount = canvas.width*canvas.height
      try
        colors = thief.getPaletteFromPixels pixels, pixelCount, @colors, @quality
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
      @quality = data

exports.getComponent = -> new GetColors
