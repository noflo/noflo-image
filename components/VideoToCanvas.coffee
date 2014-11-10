noflo = require 'noflo'

if noflo.isBrowser()
  requestAnimationFrame =
    window.requestAnimationFrame       ||
    window.webkitRequestAnimationFrame ||
    window.mozRequestAnimationFrame    ||
    window.oRequestAnimationFrame      ||
    window.msRequestAnimationFrame     ||
    (callback, element) ->
      window.setTimeout( ->
        callback(+new Date())
      , 1000 / 60)

class VideoToCanvas extends noflo.Component
  description: 'Convert video to canvas.'
  icon: 'file-image-o'

  constructor: ->
    @video = null
    @lastTime = -1
    @canvas = null
    @context = null
    @shutdownNextFrame = false
    @rafLooping = false

    @inPorts = new noflo.InPorts
      video:
        description: 'video element to draw to canvas'
        datatype: 'object'
        required: true
      canvas:
        description: '(optional) if not hit, component will create canvas'
        datatype: 'object'
        required: false

    @outPorts = new noflo.OutPorts
      canvas:
        description: 'will send canvas with each video frame drawn'
        datatype: 'object'

    @inPorts.video.on 'data', (video) =>
      return unless video?.tagName is 'VIDEO'
      @video = video
      @lastTime = -1
      unless @rafLooping
        @rafLooping = true
        @videoToCanvas()

    @inPorts.canvas.on 'data', (canvas) =>
      @canvas = canvas
      @context = @canvas.getContext '2d'

  videoToCanvas: =>
    return if @shutdownNextFrame

    requestAnimationFrame @videoToCanvas

    unless @canvas
      unless @video.videoWidth
        # Metadata not loaded yet
        return
      if noflo.isBrowser()
        @canvas = document.createElement 'canvas'
        @canvas.width = @video.videoWidth
        @canvas.height = @video.videoHeight
      else
        Canvas = require 'canvas'
        @canvas = new Canvas @video.videoWidth, @video.videoHeight
      @context = @canvas.getContext '2d'

    if @lastTime is @video.currentTime
      # Frame hasn't advanced
      return
    else
      @lastTime = @video.currentTime

    @context.drawImage @video, 0, 0

    if @outPorts.canvas.isAttached()
      @outPorts.canvas.send @canvas

  shutdown: =>
    @shutdownNextFrame = true

exports.getComponent = -> new VideoToCanvas
