noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  ImageToCanvas = require '../components/ImageToCanvas.coffee'
  testutils = require './testutils'
else
  ImageToCanvas = require 'noflo-image/components/ImageToCanvas.js'
  testutils = require 'noflo-image/spec/testutils.js'


describe 'ImageToCanvas component', ->

  c = null
  inImage = null
  outCanvas = null
  beforeEach ->
    c = ImageToCanvas.getComponent()
    inImage = noflo.internalSocket.createSocket()
    outCanvas = noflo.internalSocket.createSocket()
    c.inPorts.image.attach inImage
    c.outPorts.canvas.attach outCanvas

  describe 'when instantiated', ->
    it 'should have one input ports', ->
      chai.expect(c.inPorts.image).to.be.an 'object'
    it 'should have one output port', ->
      chai.expect(c.outPorts.canvas).to.be.an 'object'

  describe 'with local JPG image', ->
    it 'should make a canvas with the correct size', (done) ->
      @timeout 2000
      outCanvas.once 'data', (data) ->
        chai.expect(data).isObject
        chai.expect(data.width).to.equal 1024
        chai.expect(data.height).to.equal 681
        done()

      url = 'textRegion/3010029968_02742a1aec_b.jpg'
      id = testutils.getCanvasWithImage url, (image) ->
        inImage.send image
  
