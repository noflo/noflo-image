noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  GetGIFFrame = require '../components/GetGIFFrame.coffee'
  testutils = require './testutils'
  gm = require 'gm'
else
  GetGIFFrame = require 'noflo-image/components/GetGIFFrame.js'
  testutils = require 'noflo-image/spec/testutils.js'

describe 'GetGIFFrame component', ->
  c = null
  ins = null
  frame = null
  out = null
  error = null

  beforeEach ->
    c = GetGIFFrame.getComponent()
    ins = noflo.internalSocket.createSocket()
    frame = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()
    error = noflo.internalSocket.createSocket()

    c.inPorts.in.attach ins
    c.inPorts.frame.attach frame
    c.outPorts.out.attach out
    c.outPorts.error.attach error

  describe 'when instantiated', ->
    it 'should have input ports', ->
      chai.expect(c.inPorts.in).to.be.an 'object'
      chai.expect(c.inPorts.frame).to.be.an 'object'
    it 'should have output ports', ->
      chai.expect(c.outPorts.out).to.be.an 'object'
    it 'should have error port', ->
      chai.expect(c.outPorts.error).to.be.an 'object'

  describe 'when passed a GIF filepath', ->
    describe 'with a valid frame number', ->
      it 'should extract a frame as a temporary filepath', (done) ->
        @timeout 20000
        groupId = 'gif-filepath-valid-frame'
        groups = []
        out.once 'begingroup', (group) ->
          groups.push group
        out.once 'endgroup', (group) ->
          groups.pop()
        out.once 'data', (data) ->
          gm.compare data, './spec/fixtures/first_frame.gif', (err, isEqual, equality) ->
            chai.expect(isEqual).to.be.true
            done()
        error.once 'data', (err) ->
          done err

        inSrc = './spec/fixtures/animated.gif'
        ins.beginGroup groupId
        frame.send 0
        ins.send inSrc
        ins.endGroup()

