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

  describe 'calculating aspect ratios', ->
    it 'should be able to return correct for 1680 x 1050 image', (done) ->
      ratio.on 'data', (data) ->
        chai.expect(data.ratio).to.eql [8, 5]
        done()
      dimensions.send
        width: 1680
        height: 1050
    it 'should be able to return correct for 80 x 80 image', (done) ->
      ratio.on 'data', (data) ->
        chai.expect(data.ratio).to.eql [1, 1]
        done()
      dimensions.send
        width: 80
        height: 80
    it 'should be able to return correct for 1080 x 1920 image', (done) ->
      ratio.on 'data', (data) ->
        chai.expect(data.ratio).to.eql [9, 16]
        done()
      dimensions.send
        width: 1080
        height: 1920
