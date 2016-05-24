noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  GetBorderlessBox = require '../components/GetBorderlessBox.coffee'
  testutils = require './testutils'
else
  GetBorderlessBox = require 'noflo-image/components/GetBorderlessBox.js'
  testutils = require 'noflo-image/spec/testutils.js'

checkSimilar = (chai, bbox, expected, delta) ->
  chai.expect(bbox.x).to.be.closeTo expected.x, delta
  chai.expect(bbox.y).to.be.closeTo expected.y, delta
  chai.expect(bbox.width).to.be.closeTo expected.width, delta
  chai.expect(bbox.height).to.be.closeTo expected.height, delta

fixtures = [
  id: 'not crop a blank image'
  src: 'borders/border-blank.png'
  expected:
    x: 0
    y: 0
    width: 10
    height: 20
,
  id: 'not crop on right side only'
  src: 'borders/border-right.png'
  expected:
      x: 0
      y: 0
      width: 200
      height: 150
,
  id: 'not crop on right side only, with artefacts'
  src: 'borders/border-neumann.png'
  expected:
    x: 0
    y: 0
    width: 733
    height: 731
,
  id: 'not crop on left side only'
  src: 'borders/border-left.png'
  expected:
    x: 0
    y: 0
    width: 200
    height: 150
,
  id: 'not crop on top side only'
  src: 'borders/border-top.png'
  expected:
    x: 0
    y: 0
    width: 200
    height: 150
,
  id: 'not crop on bottom side only'
  src: 'borders/border-bottom.png'
  expected:
    x: 0
    y: 0
    width: 200
    height: 150
,
  id: 'crop around a polygon'
  expected:
    x: 0
    y: 0
    width: 200
    height: 150
  src: 'borders/border-polygon.png'
,
  id: 'not crop around circles'
  expected:
    x: 0
    y: 0
    width: 200
    height: 150
  src: 'borders/border-circles.png'
,
  id: 'crop around stripes'
  expected:
    x: 0
    y: 12
    width: 200
    height: 126
  src: 'borders/border-stripes.png'
,
  id: 'crop around pyramid'
  expected:
    x: 0
    y: 0
    width: 200
    height: 150
  src: 'borders/border-pyramid.png'
,
  id: 'crop around pyramid (blur)'
  expected:
    x: 0
    y: 0
    width: 200
    height: 150
  src: 'borders/border-pyramid-blur.jpg'
,
  id: 'crop left and right borders around non-continuous lines'
  src: 'borders/border-non-continuous-lines.jpg'
  expected:
    x: 32
    y: 0
    width: 529
    height: 338
,
  id: 'not crop background color'
  src: 'borders/border-header.png'
  expected:
    x: 0
    y: 0
    width: 1952
    height: 512
,
  id: 'crop on left and right sides (YouTube preview)'
  src: 'borders/border-left-right.jpg'
  expected:
    x: 56
    y: 0
    width: 368
    height: 360
,
  id: 'not remove negative spaces'
  src: 'borders/border-negative.jpg'
  expected:
    x: 0
    y: 0
    width: 1024
    height: 683
,
  id: 'not remove negative spaces #2'
  src: 'borders/border-negative2.jpg'
  expected:
    x: 0
    y: 0
    width: 1024
    height: 683
,
  id: 'remove top and bottom borders from Youtube previews'
  src: 'borders/border-top-bottom-youtube.jpg'
  expected:
    x: 0
    y: 80
    width: 480
    height: 208
,
  id: 'remove top and bottom borders'
  src: 'borders/border-top-bottom.jpg'
  expected:
    x: 0
    y: 48
    width: 480
    height: 264
,
  id: 'remove top and bottom white borders'
  src: 'borders/borders-top-bottom-white.jpg'
  expected:
    x: 0
    y: 103
    width: 640
    height: 433
,
  id: 'remove left and right black borders'
  src: 'borders/border-left-right-black.jpg'
  expected:
    x: 64
    y: 0
    width: 1152
    height: 720
,
  id: 'not remove borders from a image with solid background'
  src: 'borders/border-solid.jpg'
  expected:
    x: 0
    y: 0
    width: 80
    height: 80
,
  id: 'not remove borders from a flag'
  src: 'borders/border-flag.jpg'
  expected:
    x: 0
    y: 0
    width: 1400
    height: 1075
,
  id: 'not remove borders from an image with different sizes of borders'
  src: 'borders/border-different.jpg'
  expected:
    x: 0
    y: 0
    width: 480
    height: 360
,
  id: 'not remove borders from an image that has all the borders',
  src: 'borders/border-all.jpeg'
  expected:
    x: 0
    y: 0
    width: 648
    height: 371
,
  id: 'not crop images of logos'
  src: 'borders/border-logo.png'
  expected:
    x: 0
    y: 0
    width: 300
    height: 300
,
  id: 'not crop images of logos #2'
  expected:
    x: 0
    y: 0
    width: 100
    height: 100,
  src: 'borders/border-logo2.png'
]

describe 'GetBorderlessBox component', ->
  c = null
  canvas = null
  mean = null
  max = null
  avg = null
  out = null

  beforeEach ->
    c = GetBorderlessBox.getComponent()
    canvas = noflo.internalSocket.createSocket()
    mean = noflo.internalSocket.createSocket()
    max = noflo.internalSocket.createSocket()
    avg = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()

    c.inPorts.canvas.attach canvas
    c.inPorts.mean.attach mean
    c.inPorts.max.attach max
    c.inPorts.avg.attach avg
    c.outPorts.rectangle.attach out

  describe 'when instantiated', ->
    it 'should have input ports', ->
      chai.expect(c.inPorts.canvas).to.be.an 'object'
      chai.expect(c.inPorts.mean).to.be.an 'object'
      chai.expect(c.inPorts.max).to.be.an 'object'
      chai.expect(c.inPorts.avg).to.be.an 'object'
    it 'should have output ports', ->
      chai.expect(c.outPorts.rectangle).to.be.an 'object'

  describe 'when passed a canvas', ->

    fixtures.forEach (fixture) ->
      {id, src, expected} = fixture
      it "should #{id}", (done) ->
        @timeout 10000
        groups = []
        out.once 'begingroup', (group) ->
          groups.push group
        out.once 'endgroup', (group) ->
          groups.pop()
        out.once 'data', (res) ->
          chai.expect(groups).to.be.eql [id]
          # testutils.getCanvasWithImageNoShift src, (c) ->
          #   testutils.cropAndSave "#{src}_borderless.png", c, res
          checkSimilar chai, res, expected, 3
          done()

        testutils.getCanvasWithImageNoShift src, (c) ->
          canvas.beginGroup id
          canvas.send c
          canvas.endGroup()
