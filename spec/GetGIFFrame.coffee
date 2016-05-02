noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  GetGIFFrame = require '../components/GetGIFFrame.coffee'
  testutils = require './testutils'
else
  GetGIFFrame = require 'noflo-image/components/GetGIFFrame.js'
  testutils = require 'noflo-image/spec/testutils.js'

describe 'GetGIFFrame component', ->
  c = null
  ins = null
  frame = null
  out = null

  beforeEach ->
    c = Crop.getComponent()
    ins = noflo.internalSocket.createSocket()
    frame = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()

    c.inPorts.in.attach ins
    c.inPorts.frame.attach frame
    c.outPorts.out.attach out

  describe 'when instantiated', ->
    it 'should have input ports', ->
      chai.expect(c.inPorts.in).to.be.an 'object'
      chai.expect(c.inPorts.frame).to.be.an 'object'
    it 'should have output ports', ->
      chai.expect(c.outPorts.out).to.be.an 'object'

  describe 'when passed a GIF filepath', ->
    describe 'with a valid frame number', ->
      it 'should extract it', (done) ->
        @timeout 20000
        groupId = 'gif-filepath-valid-frame'
        groups = []
        out.once 'begingroup', (group) ->
          groups.push group
        out.once 'endgroup', (group) ->
          groups.pop()
        out.once 'data', (res) ->
          done()

        inSrc = 'animated.gif'
        ins.beginGroup groupId
        ins.send inSrc
        ins.endGroup()

