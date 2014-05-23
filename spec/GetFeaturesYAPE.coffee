noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  fs = require 'fs'
  Canvas = require 'canvas'
  GetFeaturesYAPE = require '../components/GetFeaturesYAPE.coffee'
else
  GetFeaturesYAPE = require 'noflo-canvas/components/GetFeaturesYAPE.js'


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

getData = (name) ->
    p = './fixtures/' + name
    require p

describe 'GetFeaturesYAPE component', ->
  c = null
  ins = null
  corners = null
  canvas = null
  beforeEach ->
    c = GetFeaturesYAPE.getComponent()
    ins = noflo.internalSocket.createSocket()
    corners = noflo.internalSocket.createSocket()
    canvas = noflo.internalSocket.createSocket()
    c.inPorts.canvas.attach ins
    c.outPorts.corners.attach corners
    c.outPorts.canvas.attach canvas

  describe 'when instantiated', ->
    it 'should have an input port', ->
      chai.expect(c.inPorts.canvas).to.be.an 'object'
    it 'should have output ports', ->
      chai.expect(c.outPorts.corners).to.be.an 'object'
      chai.expect(c.outPorts.canvas).to.be.an 'object'

  describe 'when passed a canvas', ->
    input = 'textAnywhere/flickr-3178100324-original_small.jpg'
    ref = 'textAnywhere/flickr-3178100324-original_small.corners.json'
    expected = (getData ref).corners
    it 'should extract corners', (done) ->
      id = null
      groups = []
      corners.once "begingroup", (group) ->
        groups.push group
      corners.once "data", (corners) ->
        unless noflo.isBrowser()
            fs.writeFileSync 'spec/fixtures/'+ref+'.out', JSON.stringify { corners: corners }
        chai.expect(corners).to.be.an 'array'
        chai.expect(corners).to.have.length expected.length
        chai.expect(corners[0]).to.be.an 'object'
        chai.expect(corners[0]).to.have.property 'x'
        chai.expect(corners[0]).to.have.property 'y'
        chai.expect(corners[0]).to.have.property 'score'
        chai.expect(corners[0]).to.have.property 'level'
        chai.expect(corners).to.deep.equal expected
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
