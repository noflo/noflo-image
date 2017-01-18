noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
  testutils = require './testutils'
else
  baseDir = '/noflo-image'
  testutils = require 'noflo-image/spec/testutils.js'

describe 'ImageToCanvas component', ->
  c = null
  inImage = null
  outCanvas = null

  beforeEach (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'image/ImageToCanvas', (err, instance) ->
      return done err if err
      c = instance
      inImage = noflo.internalSocket.createSocket()
      outCanvas = noflo.internalSocket.createSocket()
      c.inPorts.image.attach inImage
      c.outPorts.canvas.attach outCanvas
      done()

  describe 'when instantiated', ->
    it 'should have one input ports', ->
      chai.expect(c.inPorts.image).to.be.an 'object'
    it 'should have one output port', ->
      chai.expect(c.outPorts.canvas).to.be.an 'object'

  describe 'with local JPG image', ->
    it 'should make a canvas with the correct size', (done) ->
      @timeout 2000
      outCanvas.once 'data', (data) ->
        chai.expect(data.width).to.equal 1024
        chai.expect(data.height).to.equal 681
        done()

      url = 'textRegion/3010029968_02742a1aec_b.jpg'
      id = testutils.getCanvasWithImage url, (image) ->
        inImage.send image
