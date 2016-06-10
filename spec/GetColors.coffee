noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  fs = require 'fs'
  Canvas = require('noflo-canvas').canvas
  GetColors = require '../components/GetColors.coffee'
else
  GetColors = require 'noflo-image/components/GetColors.js'


createCanvas = (width, height) ->
  if noflo.isBrowser()
    canvas = document.createElement 'canvas'
    canvas.width = width
    canvas.height = height
  else
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
    canvas.getContext('2d').drawImage(img, 0, 0)
    callback canvas
  return id

describe 'GetColors component', ->
  c = null
  ins = null
  colors = null
  canvas = null
  error = null
  beforeEach ->
    c = GetColors.getComponent()
    ins = noflo.internalSocket.createSocket()
    colors = noflo.internalSocket.createSocket()
    canvas = noflo.internalSocket.createSocket()
    error = noflo.internalSocket.createSocket()
    c.inPorts.canvas.attach ins
    c.outPorts.colors.attach colors
    c.outPorts.canvas.attach canvas
    c.outPorts.error.attach error

  describe 'when instantiated', ->
    it 'should have a input ports', ->
      chai.expect(c.inPorts.canvas).to.be.an 'object'
      chai.expect(c.inPorts.css).to.be.an 'object'
      chai.expect(c.inPorts.colors).to.be.an 'object'
      chai.expect(c.inPorts.quality).to.be.an 'object'
    it 'should have output ports', ->
      chai.expect(c.outPorts.colors).to.be.an 'object'
      chai.expect(c.outPorts.canvas).to.be.an 'object'
      chai.expect(c.outPorts.error).to.be.an 'object'

  describe 'when passed a canvas', ->
    input = 'colorful-octagon.png'
    expected = [
      [0, 0, 0]
      [255, 0, 0]
      [255, 255, 0]
      [0, 0, 255]
      [0, 255, 255]
      [0, 255, 0]
      [255, 0, 255]
      [255, 255, 255]
      [0, 95, 95]
      [156, 156, 0]
    ]
    it 'should extract the prominent colors', (done) ->
      id = null
      groups = []
      colors.once "begingroup", (group) ->
        groups.push group
      colors.once "data", (colors) ->
        chai.expect(colors).to.be.an 'array'
        chai.expect(colors).to.have.length expected.length
        chai.expect(colors[0]).to.be.an 'array'
        chai.expect(colors[0]).to.have.length 3
        chai.expect(colors).to.deep.equal expected
        chai.expect(groups).to.have.length 1
        chai.expect(groups[0]).to.equal id
        done()
      id = getCanvasWithImage input, (canvas) ->
        ins.beginGroup id
        ins.send canvas
        ins.endGroup()

    it 'should send canvas out', (done) ->
      id = null
      groups = []
      canvas.once "begingroup", (group) ->
        groups.push group
      canvas.once "data", (canvas) ->
        chai.expect(canvas).to.be.an 'object'
        chai.expect(groups).to.have.length 1
        chai.expect(groups[0]).to.equal id
        done()
      id = getCanvasWithImage input, (canvas) ->
        ins.beginGroup id
        ins.send canvas
        ins.endGroup()

  describe 'when css color option is true', ->
    ins_css = null
    beforeEach ->
      ins_css = noflo.internalSocket.createSocket()
      c.inPorts.css.attach ins_css
      ins_css.send true

    input = 'colorful-octagon.png'

    expected = [
      "rgb(0, 0, 0)"
      "rgb(255, 0, 0)"
      "rgb(255, 255, 0)"
      "rgb(0, 0, 255)"
      "rgb(0, 255, 255)"
      "rgb(0, 255, 0)"
      "rgb(255, 0, 255)"
      "rgb(255, 255, 255)"
      "rgb(0, 95, 95)"
      "rgb(156, 156, 0)"
    ]
    it 'should extract the colors and output css strings', (done) ->
      colors.once "data", (colors) ->
        chai.expect(colors).to.be.an 'array'
        chai.expect(colors).to.have.length expected.length
        chai.expect(colors[0]).to.be.a 'string'
        chai.expect(colors).to.deep.equal expected
        done()
      id = getCanvasWithImage input, (canvas) ->
        ins.beginGroup id
        ins.send canvas
        ins.endGroup()
  describe 'when given a small image', ->
    it 'should output no colors', (done) ->
      input = '1x1.gif'
      id = null
      colors.once "data", (colors) ->
        chai.expect(colors).to.be.an 'array'
        chai.expect(colors).to.have.length 0
        done()
      id = getCanvasWithImage input, (canvas) ->
        ins.send canvas
  describe 'when given not an image', ->
    it 'should return an error', (done) ->
      error.on "data", (err) ->
        chai.expect(err).to.be.an 'object'
        done()
      ins.send ''
  describe 'when given null', ->
    it 'should return an error', (done) ->
      error.on "data", (err) ->
        chai.expect(err).to.be.an 'object'
        done()
      ins.send null
