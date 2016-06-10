noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  CalculateAspectRatio = require '../components/CalculateAspectRatio.coffee'
else
  CalculateAspectRatio = require 'noflo-image/components/CalculateAspectRatio.js'

describe 'CalculateAspectRatio component', ->
  c = null
  dimensions = null
  ratio = null
  error = null
  beforeEach ->
    c = CalculateAspectRatio.getComponent()
    dimensions = noflo.internalSocket.createSocket()
    ratio = noflo.internalSocket.createSocket()
    error = noflo.internalSocket.createSocket()
    c.inPorts.dimensions.attach dimensions
    c.outPorts.ratio.attach ratio
    c.outPorts.error.attach error

  describe 'calculating aspect ratios', ->
    it 'should be able to return correct for 1680 x 1050 image', (done) ->
      ratio.on 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.ratio).to.be.a 'string'
        chai.expect(data.ratio).to.eql '8:5'
        chai.expect(data.aspect).to.be.a 'number'
        chai.expect(data.aspect).to.be.eql 1680/1050
        done()
      dimensions.send
        width: 1680
        height: 1050
    it 'should be able to return correct for 80 x 80 image', (done) ->
      ratio.on 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.ratio).to.be.a 'string'
        chai.expect(data.ratio).to.eql '1:1'
        chai.expect(data.aspect).to.be.a 'number'
        chai.expect(data.aspect).to.eql 80/80
        done()
      dimensions.send
        width: 80
        height: 80
    it 'should be able to return correct for 1080 x 1920 image', (done) ->
      ratio.on 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.ratio).to.be.a 'string'
        chai.expect(data.ratio).to.eql '9:16'
        chai.expect(data.aspect).to.be.a 'number'
        chai.expect(data.aspect).to.be.eql 1080/1920
        done()
      dimensions.send
        width: 1080
        height: 1920
    it 'should return error for a image without width or height', (done) ->
      error.on 'data', (err) ->
        chai.expect(err).to.be.an 'object'
        done()
      dimensions.send
        width: 1080
