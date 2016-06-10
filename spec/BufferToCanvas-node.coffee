noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  BufferToCanvas = require '../components/BufferToCanvas-node.coffee'
  testutils = require './testutils'
else
  BufferToCanvas = require 'noflo-image/components/BufferToCanvas-node.js'
  testutils = require 'noflo-image/spec/testutils.js'

describe 'BufferToCanvas component', ->
  c = null
  inBuffer = null
  outCanvas = null
  error = null

  beforeEach ->
    c = BufferToCanvas.getComponent()
    inBuffer = noflo.internalSocket.createSocket()
    outCanvas = noflo.internalSocket.createSocket()
    error = noflo.internalSocket.createSocket()
    c.inPorts.buffer.attach inBuffer
    c.outPorts.canvas.attach outCanvas
    c.outPorts.error.attach error

  describe 'when instantiated', ->
    it 'should have one input ports', ->
      chai.expect(c.inPorts.buffer).to.be.an 'object'
    it 'should have a output port', ->
      chai.expect(c.outPorts.canvas).to.be.an 'object'
    it 'should have an error output port', ->
      chai.expect(c.outPorts.error).to.be.an 'object'

  describe 'with a buffer', ->
    @timeout 1000
    it 'should make a canvas with the correct size', (done) ->
      groupId = 'buffer-canvas'
      groups = []
      outCanvas.once 'begingroup', (group) ->
        groups.push group
      outCanvas.once 'endgroup', (group) ->
        groups.pop()
      outCanvas.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.width).to.equal 80
        chai.expect(data.height).to.equal 80
        done()
      error.once 'data', (err) -> done(err)

      url = 'saturation.png'
      buffer = testutils.getBuffer url
      inBuffer.beginGroup groupId
      inBuffer.send buffer
      inBuffer.endGroup()

  describe 'with a zero sized buffer', ->
    it 'should return an error', (done) ->
      @timeout 1000
      error.on 'data', (err) ->
        chai.expect(err).to.be.an 'object'
        done()
      buffer = ''
      inBuffer.send buffer
  describe 'with a empty buffer', ->
    it 'should return an error', (done) ->
      @timeout 1000
      error.on 'data', (err) ->
        chai.expect(err).to.be.an 'object'
        done()
      inBuffer.send {}
  describe 'with a null buffer', ->
    it 'should return an error', (done) ->
      @timeout 1000
      error.on 'data', (err) ->
        chai.expect(err).to.be.an 'object'
        done()
      inBuffer.send null
  describe 'with a not buffer', ->
    it 'should return an error', (done) ->
      @timeout 1000
      error.on 'data', (err) ->
        chai.expect(err).to.be.an 'object'
        done()
      inBuffer.send 42
