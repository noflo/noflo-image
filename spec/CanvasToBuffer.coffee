noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  CanvasToBuffer = require '../components/CanvasToBuffer.coffee'
else
  CanvasToBuffer = require 'noflo-image/components/CanvasToBuffer.js'

describe 'CanvasToBuffer component', ->
  c = null
  ins = null
  out = null
  error = null
  beforeEach ->
    c = CanvasToBuffer.getComponent()
    ins = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()
    error = noflo.internalSocket.createSocket()
    c.inPorts.url.attach ins
    c.outPorts.buffer.attach out
    c.outPorts.error.attach error

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
        expected = 'spec/test-80x80.jpg'
        out.once 'data', (data) ->
          console.log 'data', data
          chai.expect(data).to.be.an 'object'
          chai.expect(data).to.be.an.instanceOf Buffer
          done()
        src = 'spec/test-80x80.jpg'
        testutils.getCanvasWithImageNoShift src, (canvas) ->
          ins.beginGroup 'foo'
          ins.send canvas
          ins.endGroup()

