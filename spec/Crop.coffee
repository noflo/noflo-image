noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
  testutils = require './testutils'
else
  baseDir = '/noflo-image'
  testutils = require 'noflo-image/spec/testutils.js'

describe 'Crop component', ->
  c = null
  canvas = null
  rectangle = null
  out = null
  error = null
  beforeEach (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'image/Crop', (err, instance) ->
      return done err if err
      c = instance
      canvas = noflo.internalSocket.createSocket()
      rectangle = noflo.internalSocket.createSocket()
      out = noflo.internalSocket.createSocket()
      error = noflo.internalSocket.createSocket()
      c.inPorts.canvas.attach canvas
      c.inPorts.rectangle.attach rectangle
      c.outPorts.canvas.attach out
      c.outPorts.error.attach error
      done()

  describe 'when instantiated', ->
    it 'should have input ports', ->
      chai.expect(c.inPorts.canvas).to.be.an 'object'
      chai.expect(c.inPorts.rectangle).to.be.an 'object'
    it 'should have output ports', ->
      chai.expect(c.outPorts.canvas).to.be.an 'object'
      chai.expect(c.outPorts.error).to.be.an 'object'

  describe 'when passed a canvas', ->
    describe 'with a valid rectangle', ->
      it 'should crop it', (done) ->
        @timeout 20000
        rect =
          x: 40
          y: 40
          width: 40
          height: 40
        groupId = 'rectangle-ranges'
        groups = []
        out.once 'begingroup', (group) ->
          groups.push group
        out.once 'endgroup', (group) ->
          groups.pop()
        out.once 'data', (res) ->
          chai.expect(res.width).to.be.eql rect.width
          chai.expect(res.height).to.be.eql rect.height
          done()

        inSrc = 'original.jpg'
        testutils.getCanvasWithImageNoShift inSrc, (c) ->
          canvas.beginGroup groupId
          rectangle.send rect
          canvas.send c
          canvas.endGroup()

    describe 'with a rectangle bigger than image', ->
      it 'should crop it respecting boundaries', (done) ->
        @timeout 20000
        groupId = 'rectangle-ranges'
        groups = []
        out.once 'begingroup', (group) ->
          groups.push group
        out.once 'endgroup', (group) ->
          groups.pop()
        out.once 'data', (res) ->
          expected =
            width: 40
            height: 40
          chai.expect(res.width).to.be.eql expected.width
          chai.expect(res.height).to.be.eql expected.height
          done()

        inSrc = 'original.jpg'
        rect =
          x: 40
          y: 40
          width: 100
          height: 100
        testutils.getCanvasWithImageNoShift inSrc, (c) ->
          canvas.beginGroup groupId
          rectangle.send rect
          canvas.send c
          canvas.endGroup()

    describe 'with a rectangle with negative coordinates', ->
      it 'should crop it respecting boundaries', (done) ->
        @timeout 20000
        groupId = 'rectangle-ranges'
        groups = []
        out.once 'begingroup', (group) ->
          groups.push group
        out.once 'endgroup', (group) ->
          groups.pop()
        out.once 'data', (res) ->
          expected =
            width: 80
            height: 80
          chai.expect(res.width).to.be.eql expected.width
          chai.expect(res.height).to.be.eql expected.height
          done()

        inSrc = 'original.jpg'
        rect =
          x: -40
          y: -40
          width: 80
          height: 80
        testutils.getCanvasWithImageNoShift inSrc, (c) ->
          canvas.beginGroup groupId
          rectangle.send rect
          canvas.send c
          canvas.endGroup()

    describe 'when given null canvas', ->
      it 'should return an error', (done) ->
        groupId = 'null-canvas'
        groups = []
        out.once 'begingroup', (group) ->
          groups.push group
        out.once 'endgroup', (group) ->
          groups.pop()
        error.on "data", (err) ->
          chai.expect(err).to.be.instanceof Error
          done()
        rect =
          x: -40
          y: -40
          width: 80
          height: 80
        canvas.beginGroup groupId
        canvas.send null
        rectangle.send rect
        canvas.endGroup()

    describe 'when given null rectangle', ->
      it 'should return an error', (done) ->
        groupId = 'null-rectangle'
        groups = []
        out.once 'begingroup', (group) ->
          groups.push group
        out.once 'endgroup', (group) ->
          groups.pop()
        error.on "data", (err) ->
          chai.expect(err).to.be.instanceof Error
          done()
        inSrc = 'original.jpg'
        testutils.getCanvasWithImageNoShift inSrc, (c) ->
          canvas.beginGroup groupId
          rectangle.send null
          canvas.send c
          canvas.endGroup()

    describe 'when given a invalid rectangle', ->
      it 'should return an error', (done) ->
        groupId = 'null-rectangle'
        groups = []
        out.once 'begingroup', (group) ->
          groups.push group
        out.once 'endgroup', (group) ->
          groups.pop()
        error.on "data", (err) ->
          chai.expect(err).to.be.instanceof Error
          done()
        inSrc = 'original.jpg'
        rect =
          x: -40
          height: 80
        testutils.getCanvasWithImageNoShift inSrc, (c) ->
          canvas.beginGroup groupId
          rectangle.send rect
          canvas.send c
          canvas.endGroup()
