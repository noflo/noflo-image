noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  VideoToCanvas = require '../components/VideoToCanvas.coffee'
  testutils = require './testutils'
else
  VideoToCanvas = require 'noflo-image/components/VideoToCanvas.js'
  testutils = require 'noflo-image/spec/testutils.js'


describe 'VideoToCanvas component', ->

  c = null
  inVideo = null
  outCanvas = null
  beforeEach ->
    c = VideoToCanvas.getComponent()
    inVideo = noflo.internalSocket.createSocket()
    outCanvas = noflo.internalSocket.createSocket()
    c.inPorts.video.attach inVideo
    c.outPorts.canvas.attach outCanvas
   
  describe 'when instantiated', ->
    it 'should have two input ports', ->
      chai.expect(c.inPorts.video).to.be.an 'object'
      chai.expect(c.inPorts.canvas).to.be.an 'object'
    it 'should have one output port', ->
      chai.expect(c.outPorts.canvas).to.be.an 'object'

# TODO! test video in, canvas out