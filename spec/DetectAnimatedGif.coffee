noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  DetectAnimatedGif = require '../components/DetectAnimatedGif.coffee'
  testutils = require './testutils'
else
  DetectAnimatedGif = require 'noflo-image/components/DetectAnimatedGif.js'
  testutils = require 'noflo-image/spec/testutils.js'


describe 'DetectAnimatedGif component', ->

  c = null
  ins = null
  out = null
  beforeEach ->
    c = DetectAnimatedGif.getComponent()
    ins = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()
    c.inPorts.buffer.attach ins
    c.outPorts.animated.attach out

  describe 'when instantiated', ->
    it 'should have one input port', ->
      chai.expect(c.inPorts.buffer).to.be.an 'object'
    it 'should have one output port', ->
      chai.expect(c.outPorts.animated).to.be.an 'object'

  describe 'with an animated GIF buffer', ->
    it 'should return true', (done) ->
      out.once 'data', (data) ->
        chai.expect(data).to.be.a 'boolean'
        chai.expect(data).to.equal true
        done()

      url = 'animated.gif'
      buffer = testutils.getBuffer url
      ins.send buffer

  describe 'with a static GIF buffer', ->
    it 'should return false', (done) ->
      out.once 'data', (data) ->
        chai.expect(data).to.be.a 'boolean'
        chai.expect(data).to.equal false
        done()

      url = 'static.gif'
      buffer = testutils.getBuffer url
      ins.send buffer

  describe 'with a non-GIF buffer', ->
    it 'should return false', (done) ->
      out.once 'data', (data) ->
        chai.expect(data).to.be.a 'boolean'
        chai.expect(data).to.equal false
        done()

      url = 'crash.png'
      buffer = testutils.getBuffer url
      ins.send buffer

  describe 'with a non-image buffer', ->
    it 'should return false', (done) ->
      out.once 'data', (data) ->
        chai.expect(data).to.be.a 'boolean'
        chai.expect(data).to.equal false
        done()

      url = '../DetectAnimatedGif.coffee'
      buffer = testutils.getBuffer url
      ins.send buffer

  describe 'with an animated GIF file', ->
    it 'should return true', (done) ->
      out.once 'data', (data) ->
        chai.expect(data).to.be.a 'boolean'
        chai.expect(data).to.equal true
        done()

      ins.send 'spec/fixtures/animated.gif'

  describe 'with an static GIF file', ->
    it 'should return true', (done) ->
      out.once 'data', (data) ->
        chai.expect(data).to.be.a 'boolean'
        chai.expect(data).to.equal false
        done()

      ins.send 'spec/fixtures/static.gif'

  describe 'with a non-GIF file', ->
    it 'should return false', (done) ->
      @timeout 5000
      out.once 'data', (data) ->
        chai.expect(data).to.be.a 'boolean'
        chai.expect(data).to.equal false
        done()

      ins.send 'spec/fixtures/crash.png'

  describe 'with a non-image file', ->
    it 'should return false', (done) ->
      out.once 'data', (data) ->
        chai.expect(data).to.be.a 'boolean'
        chai.expect(data).to.equal false
        done()

      ins.send 'spec/DetectAnimatedGif.coffee'

