noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  ExtractLightness = require '../components/ExtractLightness.coffee'
  testutils = require './testutils'
else
  ExtractLightness = require 'noflo-image/components/ExtractLightness.js'
  testutils = require 'noflo-image/spec/testutils.js'

describe 'ExtractLightness component', ->
  c = null
  ins = null
  paths = null
  out = null

  beforeEach ->
    c = ExtractLightness.getComponent()
    ins = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()

    c.inPorts.canvas.attach ins
    c.outPorts.lightness.attach out

  describe 'when instantiated', ->
    it 'should have input ports', ->
      chai.expect(c.inPorts.canvas).to.be.an 'object'
    it 'should have output ports', ->
      chai.expect(c.outPorts.lightness).to.be.an 'object'

  describe 'when passed a canvas', ->
    it 'should extract global lightness', (done) ->
      id = 1
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.eql [1]
        chai.expect(res).to.be.a 'number'
        chai.expect(res).to.be.closeTo 0.8, 2.0
        done()

      inSrc = 'original.jpg'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        ins.beginGroup id
        ins.send c
        ins.endGroup()

  describe 'when passed a light canvas', ->
    it 'should extract high lightness level', (done) ->
      id = 1
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.eql [1]
        chai.expect(res).to.be.a 'number'
        chai.expect(res).to.be.gte 0
        done()

      inSrc = 'light.png'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        ins.beginGroup id
        ins.send c
        ins.endGroup()

  describe 'when passed a dark canvas', ->
    it 'should extract low lightness level', (done) ->
      id = 1
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.eql [1]
        chai.expect(res).to.be.a 'number'
        chai.expect(res).to.be.lte 0
        done()

      inSrc = 'dark.png'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        ins.beginGroup id
        ins.send c
        ins.endGroup()
