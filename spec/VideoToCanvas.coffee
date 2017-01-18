noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
  testutils = require './testutils'
else
  baseDir = '/noflo-image'
  testutils = require 'noflo-image/spec/testutils.js'

describe 'VideoToCanvas component', ->
  c = null
  inVideo = null
  outCanvas = null

  beforeEach (done) ->
    @timeout 10000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'image/VideoToCanvas', (err, instance) ->
      return done err if err
      c = instance
      inVideo = noflo.internalSocket.createSocket()
      outCanvas = noflo.internalSocket.createSocket()
      c.inPorts.video.attach inVideo
      c.outPorts.canvas.attach outCanvas
      done()

  describe 'when instantiated', ->
    it 'should have two input ports', ->
      chai.expect(c.inPorts.video).to.be.an 'object'
      chai.expect(c.inPorts.canvas).to.be.an 'object'
    it 'should have one output port', ->
      chai.expect(c.outPorts.canvas).to.be.an 'object'

# TODO! test video in, canvas out
