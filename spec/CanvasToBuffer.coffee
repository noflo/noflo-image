noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
  testutils = require './testutils'
else
  baseDir = '/noflo-image'
  testutils = require 'noflo-image/spec/testutils.js'

describe 'CanvasToBuffer component', ->
  c = null
  ins = null
  out = null
  error = null
  beforeEach (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'image/CanvasToBuffer', (err, instance) ->
      return done err if err
      c = instance
      ins = noflo.internalSocket.createSocket()
      out = noflo.internalSocket.createSocket()
      error = noflo.internalSocket.createSocket()
      c.inPorts.canvas.attach ins
      c.outPorts.buffer.attach out
      c.outPorts.error.attach error
      done()

  describe 'when instantiated', ->
    it 'should have input ports', ->
      chai.expect(c.inPorts.canvas).to.be.an 'object'
    it 'should have output ports', ->
      chai.expect(c.outPorts.buffer).to.be.an 'object'
    it 'should have an error output port', ->
      chai.expect(c.outPorts.error).to.be.an 'object'

  describe 'when sending a canvas', ->
    unless noflo.isBrowser()
      it 'should return a buffer', (done) ->
        @timeout 5000
        out.once 'data', (data) ->
          chai.expect(data).to.be.an.instanceof Buffer
          done()
        src = 'original.jpg'
        testutils.getCanvasWithImageNoShift src, (canvas) ->
          ins.beginGroup 'foo'
          ins.send canvas
          ins.endGroup()

