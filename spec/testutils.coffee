noflo = require 'noflo'
unless noflo.isBrowser()
  fs = require 'fs'
  Canvas = require 'canvas'

createCanvas = (width, height) ->
  if noflo.isBrowser()
    canvas = document.createElement 'canvas'
    canvas.width = width
    canvas.height = height
  else
    Canvas = require 'canvas'
    canvas = new Canvas width, height
  return canvas

getImageData = (name, callback) ->
  if noflo.isBrowser()
    id = 'http://localhost:8000/spec/fixtures/'+name
    image = new Image()
    image.onload = ->
      callback image
    image.src = id
  else
    id = 'spec/fixtures/'+name
    fs.readFile id, (err, data) ->
      image = new Canvas.Image
      image.src = data
      callback image
  return id

getCanvasWithImage = (name, callback) ->
  id = getImageData name, (img) ->
    canvas = createCanvas img.width, img.height
    canvas.getContext('2d').drawImage img, img.width*0.25, img.height*0.25
    callback canvas
  return id

getData = (name, def) ->
  p = './fixtures/' + name
  try  
    return require p
  catch err
    console.log 'WARN: getData():', err.message
    return def || {}
  

writeOut = (path, data) ->
  path = 'spec/fixtures/'+path
  unless noflo.isBrowser()
      fs.writeFileSync path, JSON.stringify data

exports.getData = getData
exports.writeOut = writeOut
exports.getCanvasWithImage = getCanvasWithImage
