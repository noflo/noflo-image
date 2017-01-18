noflo = require 'noflo'
unless noflo.isBrowser()
  fixtures = require './fixtures'
  chai = require 'chai' unless chai
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
  testutils = require './testutils'
else
  baseDir = '/noflo-image'
  testutils = require 'noflo-image/spec/testutils.js'

describe 'GetHistogram component', ->
  @timeout 3*1000
  c = null
  canvas = null
  step = null
  out = null
  error = null

  beforeEach (done) ->
    loader = new noflo.ComponentLoader baseDir
    loader.load 'image/GetHistogram', (err, instance) ->
      return done err if err
      c = instance
      canvas = noflo.internalSocket.createSocket()
      step = noflo.internalSocket.createSocket()
      out = noflo.internalSocket.createSocket()
      error = noflo.internalSocket.createSocket()
      c.inPorts.canvas.attach canvas
      c.inPorts.step.attach step
      c.outPorts.histogram.attach out
      c.outPorts.error.attach error
      done()

  describe 'when instantiated', ->
    it 'should have input ports', ->
      chai.expect(c.inPorts.canvas).to.be.an 'object'
      chai.expect(c.inPorts.step).to.be.an 'object'
    it 'should have output ports', ->
      chai.expect(c.outPorts.histogram).to.be.an 'object'
    it 'should have an error output port', ->
      chai.expect(c.outPorts.error).to.be.an 'object'

  describe 'when passed a canvas', ->
    it 'should calculate histograms', (done) ->
      groupId = 'histogram-values'
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.be.eql ['histogram-values']
        chai.expect(res).to.be.deep.equal
        hists = 'rgbayhslc'
        for hist in hists
          expected = fixtures.histogram.colorful[hist]
          for val, i in res[hist]
            chai.expect(val, "histogram-#{hist}").to.be.closeTo expected[i], 0.001
        done()

      inSrc = 'colorful-octagon.png'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        canvas.beginGroup groupId
        step.send 2
        canvas.send c
        canvas.endGroup()

    it 'should calculate histograms even if step is higher than image size', (done) ->
      groupId = 'huge-step'
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.be.eql ['huge-step']
        chai.expect(res).to.be.deep.equal
        hists = 'rgbayhslc'
        for hist in hists
          expected = fixtures.histogram.colorful[hist]
          for val, i in res[hist]
            chai.expect(val, "histogram-#{hist}").to.be.closeTo expected[i], 0.001
        done()

      inSrc = 'colorful-octagon.png'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        canvas.beginGroup groupId
        step.send 1000000
        canvas.send c
        canvas.endGroup()

    it 'should calculate histograms even if step is not valid', (done) ->
      groupId = 'invalid-step'
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.be.eql ['invalid-step']
        chai.expect(res).to.be.deep.equal
        hists = 'rgbayhslc'
        for hist in hists
          expected = fixtures.histogram.colorful[hist]
          for val, i in res[hist]
            chai.expect(val, "histogram-#{hist}").to.be.closeTo expected[i], 0.001
        done()

      inSrc = 'colorful-octagon.png'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        canvas.beginGroup groupId
        step.send 0
        canvas.send c
        canvas.endGroup()

    it 'should calculate histograms with the right ranges', (done) ->
      groupId = 'histogram-ranges'
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.be.eql ['histogram-ranges']
        chai.expect(res.r.length).to.be.equal 256
        chai.expect(res.g.length).to.be.equal 256
        chai.expect(res.b.length).to.be.equal 256
        chai.expect(res.a.length).to.be.equal 256
        chai.expect(res.y.length).to.be.equal 256
        chai.expect(res.h.length).to.be.equal 361
        chai.expect(res.s.length).to.be.equal 101
        chai.expect(res.l.length).to.be.equal 101
        chai.expect(res.c.length).to.be.equal 135
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
        keys = ['r', 'g', 'b', 'a', 'y', 'h', 's', 'l', 'c']
        for key in keys
          histogram = res[key]
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
  describe 'when passed null', ->
    it 'should return an error', (done) ->
      error.on 'data', (err) ->
        done()
      canvas.send null
