noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  FindFreeRectangles = require '../components/FindFreeRectangles.coffee'
  testutils = require './testutils'
else
  FindFreeRectangles = require 'noflo-image/components/FindFreeRectangles.js'
  testutils = require 'noflo-image/spec/testutils.js'

describe 'FindFreeRectangles component', ->
  c = null
  inCanvas = null
  inPolygon = null
  inThreshold = null
  inMax = null
  out = null

  before ->
    c = FindFreeRectangles.getComponent()
    inCanvas = noflo.internalSocket.createSocket()
    inPolygon = noflo.internalSocket.createSocket()
    inThreshold = noflo.internalSocket.createSocket()
    inMax = noflo.internalSocket.createSocket()

    out = noflo.internalSocket.createSocket()

    c.inPorts.canvas.attach inCanvas
    c.inPorts.polygon.attach inPolygon
    c.inPorts.threshold.attach inThreshold
    c.inPorts.max.attach inMax
    c.outPorts.out.attach out
 
  describe 'when instantiated', ->
    it 'should have four input ports', ->
      chai.expect(c.inPorts.canvas).to.be.an 'object'
      chai.expect(c.inPorts.polygon).to.be.an 'object'
      chai.expect(c.inPorts.threshold).to.be.an 'object'
      chai.expect(c.inPorts.max).to.be.an 'object'

    it 'should have one output port', ->
      chai.expect(c.outPorts.out).to.be.an 'object'
 
  describe 'with file system image', ->
    it 'should find the expected free rectangles', (done) ->
      @timeout 10000
      id = 1
      expected =
        x: 0
        y: 0
        width: 1015
        height: 345
        text:
          large: 274
          medium: 912
          small: 1536
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.eql [1]
        chai.expect(res).to.be.an 'array'
        chai.expect(res.length).to.be.equal 10
        chai.expect(res[0]).to.eql expected
        done()

      inSrc = 'textRegion/3010029968_02742a1aec_b.jpg'
      testutils.getCanvasWithImageNoShift inSrc, (canvas) ->
        inCanvas.beginGroup id
        inCanvas.send canvas
        inPolygon.send [[1022, 679], [1022, 399], [897, 382], [889, 369], [814, 358], [811, 374], [748, 379], [712, 392], [672, 392], [667, 386], [666, 413], [635, 427], [593, 427], [583, 404], [548, 401], [501, 359], [414, 444], [387, 444], [387, 486], [402, 500], [419, 502], [482, 567], [508, 568], [508, 620], [499, 621], [496, 635], [500, 644], [519, 646], [522, 679]]
        inThreshold.send 10000
        inMax.send 10
        inCanvas.endGroup()
