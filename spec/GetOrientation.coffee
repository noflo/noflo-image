noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  GetOrientation = require '../components/GetOrientation.coffee'
else
  GetOrientation = require 'noflo-image/components/GetOrientation.js'

describe 'GetOrientation component', ->
  c = null
  dimensions = null
  orientation = null
  error = null
  beforeEach ->
    c = GetOrientation.getComponent()
    dimensions = noflo.internalSocket.createSocket()
    orientation = noflo.internalSocket.createSocket()
    error = noflo.internalSocket.createSocket()
    c.inPorts.dimensions.attach dimensions
    c.outPorts.orientation.attach orientation
    c.outPorts.error.attach error

  describe 'calculating orientations', ->
    it 'should be able to return correct for 1680 x 1050 image', (done) ->
      orientation.on 'data', (data) ->
        chai.expect(data.orientation).to.equal 'landscape'
        done()
      dimensions.send
        width: 1680
        height: 1050
    it 'should be able to return correct for 80 x 80 image', (done) ->
      orientation.on 'data', (data) ->
        chai.expect(data.orientation).to.equal 'square'
        done()
      dimensions.send
        width: 80
        height: 80
    it 'should be able to return correct for 1080 x 1920 image', (done) ->
      orientation.on 'data', (data) ->
        chai.expect(data.orientation).to.equal 'portrait'
        done()
      dimensions.send
        width: 1080
        height: 1920
    it 'should return error for a image without height', (done) ->
      error.on 'data', (err) ->
        chai.expect(err).to.be.an 'object'
        done()
      dimensions.send
        width: 1080
    it 'should return error for null input', (done) ->
      error.on 'data', (err) ->
        chai.expect(err).to.be.an 'object'
        done()
      dimensions.send null
