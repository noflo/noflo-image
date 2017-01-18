noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
else
  baseDir = '/noflo-image'

describe 'CalculateAspectRatio component', ->
  c = null
  dimensions = null
  ratio = null
  error = null
  beforeEach (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'image/CalculateAspectRatio', (err, instance) ->
      return done err if err
      c = instance
      dimensions = noflo.internalSocket.createSocket()
      ratio = noflo.internalSocket.createSocket()
      error = noflo.internalSocket.createSocket()
      c.inPorts.dimensions.attach dimensions
      c.outPorts.ratio.attach ratio
      c.outPorts.error.attach error
      done()

  describe 'calculating aspect ratios', ->
    it 'should be able to return correct for 1680 x 1050 image', (done) ->
      ratio.on 'data', (data) ->
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
        chai.expect(data.ratio).to.be.a 'string'
        chai.expect(data.ratio).to.eql '9:16'
        chai.expect(data.aspect).to.be.a 'number'
        chai.expect(data.aspect).to.be.eql 1080/1920
        done()
      dimensions.send
        width: 1080
        height: 1920
    it 'should return error for a image without height', (done) ->
      error.on 'data', (err) ->
        chai.expect(err).to.be.instanceof Error
        done()
      dimensions.send
        width: 1080
    it 'should return error for a image with null dimensions', (done) ->
      error.on 'data', (err) ->
        chai.expect(err).to.be.instanceof Error
        done()
      dimensions.send null
