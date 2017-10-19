noflo = require 'noflo'

getColorFromPath = (imageData, width, path) ->
  # Find the centroid
  sumx = 0
  sumy = 0
  paths = path.items
  n = paths.length
  for point in paths
    sumx += point.x
    sumy += point.y
  centroid =
    x: Math.floor sumx / n
    y: Math.floor sumy / n

  # Get color from canvas data
  offset = (centroid.x + centroid.y * width) * 4
  r = imageData.data[offset]
  g = imageData.data[offset+1]
  b = imageData.data[offset+2]

  "rgb(#{r}, #{g}, #{b})"

exports.getComponent = ->
  c = new noflo.Component
  c.icon = 'file-image-o'
  c.description = 'Extract color of path\'s centroid.'

  c.outPorts.add 'colors',
    datatype: 'array'

  c.inPorts.add 'canvas',
    datatype: 'object'
  c.inPorts.add 'paths',
    datatype: 'array'

  noflo.helpers.WirePattern c,
    in: ['canvas', 'paths']
    out: ['colors']
    forwardGroups: true
    async: true
  , (payload, groups, out, callback) ->
    {canvas, paths} = payload

    ctx = canvas.getContext '2d'
    imageData = ctx.getImageData 0, 0, canvas.width, canvas.height

    colors = []
    for path in paths
      colors.push getColorFromPath(imageData, canvas.width, path)

    out.send colors
    do callback
    return
