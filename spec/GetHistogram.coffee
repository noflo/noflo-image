noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  GetHistogram = require '../components/GetHistogram.coffee'
  testutils = require './testutils'
else
  GetHistogram = require 'noflo-image/components/GetHistogram.js'
  testutils = require 'noflo-image/spec/testutils.js'

describe 'GetHistogram component', ->
  c = null
  canvas = null
  out = null
  error = null

  beforeEach ->
    c = GetHistogram.getComponent()
    canvas = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()
    error = noflo.internalSocket.createSocket()

    c.inPorts.canvas.attach canvas
    c.outPorts.histogram.attach out
    c.outPorts.error.attach error

  describe 'when instantiated', ->
    it 'should have input ports', ->
      chai.expect(c.inPorts.canvas).to.be.an 'object'
    it 'should have output ports', ->
      chai.expect(c.outPorts.histogram).to.be.an 'object'
    it 'should have an error output port', ->
      chai.expect(c.outPorts.error).to.be.an 'object'

  describe 'when passed a canvas', ->
    it 'should calculate histograms with the right ranges', (done) ->
      groupId = 'histogram-ranges'
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.be.eql ['histogram-ranges']
        chai.expect(res).to.be.an 'object'
        chai.expect(res.r).to.be.an 'array'
        chai.expect(res.r.length).to.be.equal 256
        chai.expect(res.g).to.be.an 'array'
        chai.expect(res.g.length).to.be.equal 256
        chai.expect(res.b).to.be.an 'array'
        chai.expect(res.b.length).to.be.equal 256
        chai.expect(res.a).to.be.an 'array'
        chai.expect(res.a.length).to.be.equal 256
        chai.expect(res.y).to.be.an 'array'
        chai.expect(res.y.length).to.be.equal 256
        chai.expect(res.h).to.be.an 'array'
        chai.expect(res.h.length).to.be.equal 361
        chai.expect(res.s).to.be.an 'array'
        chai.expect(res.s.length).to.be.equal 101
        chai.expect(res.l).to.be.an 'array'
        chai.expect(res.l.length).to.be.equal 101
        chai.expect(res.c).to.be.an 'array'
        chai.expect(res.c.length).to.be.equal 101
        done()

      inSrc = 'original.jpg'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        canvas.beginGroup groupId
        canvas.send c
        canvas.endGroup()

    it 'should calculate normalized histograms', (done) ->
      groupId = 'histogram-normalized'
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.be.eql ['histogram-normalized']
        chai.expect(res).to.be.an 'object'
        keys = ['r', 'g', 'b', 'a', 'y', 'h', 's', 'l', 'c']
        for key in keys
          histogram = res[key]
          chai.expect(histogram).to.be.an 'array'
          sum = histogram.reduce (a,b) -> return a + b
          chai.expect(sum).to.be.closeTo 1.0, 1.0
        done()

      inSrc = 'original.jpg'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        canvas.beginGroup groupId
        canvas.send c
        canvas.endGroup()

  describe 'when passed a saturated canvas', ->
    it 'should calculate S-histogram concentrated in high spectrum', (done) ->
      groupId = 'histogram-saturated'
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.be.eql ['histogram-saturated']
        chai.expect(res).to.be.an 'object'
        chai.expect(res.s).to.be.an 'array'
        histogram = res.s
        low = histogram.slice 0, histogram.length/2
        sumLow = low.reduce (a,b) -> return a + b
        high = histogram.slice histogram.length/2
        sumHigh = high.reduce (a,b) -> return a + b
        chai.expect(sumHigh).to.be.gte 0.5
        chai.expect(sumLow).to.be.lte 0.5
        done()

      inSrc = 'saturation.png'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        canvas.beginGroup groupId
        canvas.send c
        canvas.endGroup()

  describe 'when passed a muted canvas', ->
    it 'should calculate S-histogram concentrated in low spectrum', (done) ->
      groupId = 'histogram-muted'
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.be.eql ['histogram-muted']
        chai.expect(res).to.be.an 'object'
        chai.expect(res.s).to.be.an 'array'
        histogram = res.s
        low = histogram.slice 0, histogram.length/2
        sumLow = low.reduce (a,b) -> return a + b
        high = histogram.slice histogram.length/2
        sumHigh = high.reduce (a,b) -> return a + b
        chai.expect(sumHigh).to.be.lte 0.5
        chai.expect(sumLow).to.be.gte 0.5
        done()

      inSrc = 'muted.png'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        canvas.beginGroup groupId
        canvas.send c
        canvas.endGroup()

  describe 'when passed a light canvas', ->
    it 'should calculate L-histogram concentrated in high spectrum', (done) ->
      groupId = 'histogram-light'
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.be.eql ['histogram-light']
        chai.expect(res).to.be.an 'object'
        chai.expect(res.l).to.be.an 'array'
        histogram = res.l
        low = histogram.slice 0, histogram.length/2
        sumLow = low.reduce (a,b) -> return a + b
        high = histogram.slice histogram.length/2
        sumHigh = high.reduce (a,b) -> return a + b
        chai.expect(sumHigh).to.be.gte 0.5
        chai.expect(sumLow).to.be.lte 0.5
        done()

      inSrc = 'light.png'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        canvas.beginGroup groupId
        canvas.send c
        canvas.endGroup()

  describe 'when passed a dark canvas', ->
    it 'should calculate L-histogram concentrated in low spectrum', (done) ->
      groupId = 'histogram-dark'
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.be.eql ['histogram-dark']
        chai.expect(res).to.be.an 'object'
        chai.expect(res.l).to.be.an 'array'
        histogram = res.l
        low = histogram.slice 0, histogram.length/2
        sumLow = low.reduce (a,b) -> return a + b
        high = histogram.slice histogram.length/2
        sumHigh = high.reduce (a,b) -> return a + b
        chai.expect(sumHigh).to.be.lte 0.5
        chai.expect(sumLow).to.be.gte 0.5
        done()

      inSrc = 'dark.png'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        canvas.beginGroup groupId
        canvas.send c
        canvas.endGroup()

  describe 'when passed a canvas with any transparent pixel', ->
    it 'should calculate A-histogram with 100% frequency on 255', (done) ->
      groupId = 'histogram-alpha'
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.be.eql ['histogram-alpha']
        chai.expect(res).to.be.an 'object'
        chai.expect(res.a).to.be.an 'array'
        histogram = res.a
        chai.expect(histogram[255]).to.equal 1.0
        done()

      inSrc = 'dark.png'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        canvas.beginGroup groupId
        canvas.send c
        canvas.endGroup()

  describe 'when passed a 100% transparent canvas', ->
    it 'should calculate A-histogram with 100% frequency on zero', (done) ->
      groupId = 'histogram-alpha'
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.be.eql ['histogram-alpha']
        chai.expect(res).to.be.an 'object'
        chai.expect(res.a).to.be.an 'array'
        histogram = res.a
        # Zero alpha is transparent, so A-histogram should be all zero
        chai.expect(histogram[0]).to.equal 1.0
        done()

      inSrc = 'all-transparent.png'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        canvas.beginGroup groupId
        canvas.send c
        canvas.endGroup()

  describe 'when passed a zero sized canvas', ->
    it 'should return an error', (done) ->
      error.on 'data', (err) ->
        done()
      canvas.send ''
