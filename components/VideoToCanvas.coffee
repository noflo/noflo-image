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

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Convert video to canvas.'
  c.icon = 'file-image-o'
  c.inPorts.add 'video',
    description: 'video element to draw to canvas'
    datatype: 'object'
    required: true
  c.inPorts.add 'canvas',
    description: '(optional) if not hit, component will create canvas'
    datatype: 'object'
    required: false
  c.outPorts.add 'canvas',
    description: 'will send canvas with each video frame drawn'
    datatype: 'object'
  c.outPorts.add 'error',
    datatype: 'object'
  c.forwardBrackets =
    video: ['canvas']
  c.process (input, output) ->
    return unless input.hasData 'video'
    return if input.attached('canvas').length and not input.hasData 'canvas'
    video = input.getData 'video'
    unless video?.tagName is 'VIDEO'
      output.done new Error 'Video must be a VIDEO DOM element'
      return
    if input.hasData 'canvas'
      canvas = input.getData 'canvas'
    else
      unless video.videoWidth
        # Metadata not loaded yet
        output.done 'Video width not available'
        return
      if noflo.isBrowser()
        canvas = document.createElement 'canvas'
        canvas.width = video.videoWidth
        canvas.height = video.videoHeight
      else
        Canvas = require('noflo-canvas').canvas
        canvas = new Canvas video.videoWidth, video.videoHeight
    context = canvas.getContext '2d'

    lastTime = -1
    shutdownNextFrame = false
    extractFrame = ->
      if lastTime is video.currentTime
        # Frame hasn't advanced, wait more
        requestAnimationFrame extractFrame
        return
      if video.currentTime < lastTime
        # Video is looping, bail out
        output.done()
        return
      if video.currentTime is video.duration
        # Video finished
        output.done()
        return
      lastTime = video.currentTime
      context.drawImage video, 0, 0
      output.send
        canvas: canvas
      requestAnimationFrame extractFrame

    # Get first frame
    do extractFrame
    return
