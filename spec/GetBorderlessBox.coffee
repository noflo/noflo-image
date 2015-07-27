noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  GetBorderlessBox = require '../components/GetBorderlessBox.coffee'
  testutils = require './testutils'
else
  GetBorderlessBox = require 'noflo-image/components/GetBorderlessBox.js'
  testutils = require 'noflo-image/spec/testutils.js'

describe.only 'GetBorderlessBox component', ->
  c = null
  canvas = null
  out = null

  beforeEach ->
    c = GetBorderlessBox.getComponent()
    canvas = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()

    c.inPorts.canvas.attach canvas
    c.outPorts.rectangle.attach out

  describe 'when instantiated', ->
    it 'should have input ports', ->
      chai.expect(c.inPorts.canvas).to.be.an 'object'
    it 'should have output ports', ->
      chai.expect(c.outPorts.rectangle).to.be.an 'object'

  describe 'when passed a canvas', ->
    it 'should calculate borderless bounding box', (done) ->
      @timeout 10000
      groupId = 'rectangle-ranges'
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.be.eql ['rectangle-ranges']
        console.log res
        done()

      inSrc = 'henri.jpg'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        canvas.beginGroup groupId
        canvas.send c
        canvas.endGroup()
