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

  describe 'when passing a GIF filepath', ->
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
    describe 'with an invalid frame number', ->
      it 'should output the original GIF with no changes, as a temporary file', (done) ->
        @timeout 20000
        groupId = 'gif-filepath-invalid-frame'
        groups = []
        out.once 'begingroup', (group) ->
          groups.push group
        out.once 'endgroup', (group) ->
          groups.pop()
        out.once 'data', (data) ->
          gm.compare data, inSrc, (err, isEqual, equality) ->
            chai.expect(isEqual).to.be.true
            done()
        error.once 'data', (err) ->
          done err

        inSrc = './spec/fixtures/animated.gif'
        ins.beginGroup groupId
        frame.send 'foo'
        ins.send inSrc
        ins.endGroup()
    describe 'with no frame number', ->
      it 'should extract the first frame', (done) ->
        @timeout 20000
        groupId = 'gif-filepath-valid-frame'
        groups = []
        out.once 'begingroup', (group) ->
          groups.push group
        out.once 'endgroup', (group) ->
          groups.pop()
        out.once 'data', (data) ->
          expected = './spec/fixtures/first_frame.gif'
          gm.compare data, expected, (err, isEqual, equality) ->
            chai.expect(isEqual).to.be.true
            done()
        error.once 'data', (err) ->
          done err

        inSrc = './spec/fixtures/animated.gif'
        ins.beginGroup groupId
        ins.send inSrc
        ins.endGroup()
  describe 'when passed a non-GIF filepath', ->
    it 'should return the original filepath, unchanged', (done) ->
      @timeout 20000
      groupId = 'gif-filepath-valid-frame'
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (data) ->
        chai.expect(data).to.be.equal inSrc
        done()
      error.once 'data', (err) ->
        done err

      inSrc = './spec/fixtures/original.jpg'
      ins.beginGroup groupId
      frame.send 0
      ins.send inSrc
      ins.endGroup()
