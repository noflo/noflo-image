noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
  testutils = require './testutils'
else
  baseDir = '/noflo-image'
  testutils = require 'noflo-image/spec/testutils.js'

describe 'FindFreeRectangles component', ->
  c = null
  inCanvas = null
  inPolygon = null
  inThreshold = null
  inMax = null
  out = null

  beforeEach (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'image/FindFreeRectangles', (err, instance) ->
      return done err if err
      c = instance
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
      done()
 
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

    it 'should not find any free rectangles', (done) ->
      @timeout 10000
      id = 1
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.eql [1]
        chai.expect(res.length).to.be.equal 0
        done()

      inSrc = 'crash.png'
      testutils.getCanvasWithImageNoShift inSrc, (canvas) ->
        inCanvas.beginGroup id
        inCanvas.send canvas
        inPolygon.send [[79, 1], [79, 20], [49, 62], [21, 129], [1, 130], [1, 227], [20, 227], [42, 244], [42, 284], [27, 318], [21, 356], [1, 357], [1, 376], [21, 377], [31, 440], [43, 478], [43, 498], [698, 498], [698, 1], [343, 1], [343, 9], [350, 10], [350, 89], [343, 90], [343, 242], [350, 243], [349, 323], [296, 322], [296, 96], [260, 95], [247, 56], [225, 20], [225, 1]]
        inThreshold.send 10000
        inMax.send 10
        inCanvas.endGroup()

    it 'should find at least `max` rectangles', (done) ->
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
        chai.expect(res[0]).to.eql expected
        done()

      inSrc = 'textRegion/3010029968_02742a1aec_b.jpg'
      testutils.getCanvasWithImageNoShift inSrc, (canvas) ->
        inCanvas.beginGroup id
        inCanvas.send canvas
        inPolygon.send [[1022, 679], [1022, 399], [897, 382], [889, 369], [814, 358], [811, 374], [748, 379], [712, 392], [672, 392], [667, 386], [666, 413], [635, 427], [593, 427], [583, 404], [548, 401], [501, 359], [414, 444], [387, 444], [387, 486], [402, 500], [419, 502], [482, 567], [508, 568], [508, 620], [499, 621], [496, 635], [500, 644], [519, 646], [522, 679]]
        inThreshold.send 10000
        inMax.send 62000
        inCanvas.endGroup()
