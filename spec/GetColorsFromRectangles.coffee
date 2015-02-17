noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  GetColorsFromRectangles = require '../components/GetColorsFromRectangles.coffee'
  testutils = require './testutils'
else
  GetColorsFromRectangles = require 'noflo-image/components/GetColorsFromRectangles.js'
  testutils = require 'noflo-image/spec/testutils.js'

describe 'GetColorsFromRectangles component', ->
  c = null
  ins = null
  css = null
  colors = null
  rect = null
  out = null

  beforeEach ->
    c = GetColorsFromRectangles.getComponent()
    ins = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()
    canvas = noflo.internalSocket.createSocket()
    css = noflo.internalSocket.createSocket()
    colors = noflo.internalSocket.createSocket()
    rect = noflo.internalSocket.createSocket()

    c.inPorts.canvas.attach ins
    c.inPorts.rect.attach rect
    c.inPorts.css.attach css
    c.inPorts.colors.attach colors

    c.outPorts.out.attach out

  describe 'when instantiated', ->
    it 'should have input ports', ->
      chai.expect(c.inPorts.canvas).to.be.an 'object'
      chai.expect(c.inPorts.css).to.be.an 'object'
      chai.expect(c.inPorts.colors).to.be.an 'object'
      chai.expect(c.inPorts.rect).to.be.an 'object'
    it 'should have output ports', ->
      chai.expect(c.outPorts.out).to.be.an 'object'

  describe 'when passed a canvas and some rectangles', ->
    someRects = [ 
      { type: 'rectangle', x: 490, y: 172, width: 70, height: 230 },
      { type: 'rectangle', x: 0, y: 0, width: 160, height: 160 }
    ]
    it 'should extract colors from the rectangles', (done) ->
      @timeout 20000
      id = 1
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.eql [1]
        chai.expect(res).to.be.an 'array'
        chai.expect(res.length).to.be.equal someRects.length
        done()

      inSrc = 'colorful-octagon.png'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        ins.beginGroup id
        rect.send someRects
        css.send true
        colors.send 3
        ins.send c
        ins.endGroup()
