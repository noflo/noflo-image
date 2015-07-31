noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  GetBorderlessBox = require '../components/GetBorderlessBox.coffee'
  testutils = require './testutils'
else
  GetBorderlessBox = require 'noflo-image/components/GetBorderlessBox.js'
  testutils = require 'noflo-image/spec/testutils.js'

describe 'GetBorderlessBox component', ->
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
    it 'should remove left and right white borders', (done) ->
      @timeout 10000
      groupId = 'rectangle-ranges'
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.be.eql ['rectangle-ranges']
        expected =
          x: 38
          y: 0
          width: 522
          height: 338
        chai.expect(res).to.be.eql expected
        done()

      inSrc = 'borderless1.jpg'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        canvas.beginGroup groupId
        canvas.send c
        canvas.endGroup()

    it 'should remove left and right black borders', (done) ->
      @timeout 10000
      groupId = 'rectangle-ranges'
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.be.eql ['rectangle-ranges']
        expected =
          x: 64
          y: 0
          width: 1152
          height: 720
        chai.expect(res).to.be.eql expected
        done()

      inSrc = 'borderless2.jpg'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        canvas.beginGroup groupId
        canvas.send c
        canvas.endGroup()

    it 'should remove up and down black borders', (done) ->
      @timeout 10000
      groupId = 'rectangle-ranges'
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.be.eql ['rectangle-ranges']
        expected =
          x: 0
          y: 48
          width: 480
          height: 264
        chai.expect(res).to.be.eql expected
        done()

      inSrc = 'borderless3.jpg'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        canvas.beginGroup groupId
        canvas.send c
        canvas.endGroup()

    it 'should remove up and down white borders', (done) ->
      @timeout 10000
      groupId = 'rectangle-ranges'
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.be.eql ['rectangle-ranges']
        expected =
          x: 0
          y: 106
          width: 640
          height: 430
        chai.expect(res).to.be.eql expected
        done()

      inSrc = 'borderless4.jpg'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        canvas.beginGroup groupId
        canvas.send c
        canvas.endGroup()

    it 'should not remove borders', (done) ->
      @timeout 10000
      groupId = 'rectangle-ranges'
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.be.eql ['rectangle-ranges']
        expected =
          x: 0
          y: 0
          width: 80
          height: 80
        chai.expect(res).to.be.eql expected
        done()

      inSrc = 'original.jpg'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        canvas.beginGroup groupId
        canvas.send c
        canvas.endGroup()
