noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  Measure = require '../components/Measure-node.coffee'
else
  Measure = require 'noflo-image/components/Measure.js'

describe 'Measure component', ->
  c = null
  ins = null
  out = null
  error = null
  beforeEach ->
    c = Measure.getComponent()
    ins = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()
    error = noflo.internalSocket.createSocket()
    c.inPorts.url.attach ins
    c.outPorts.dimensions.attach out
    c.outPorts.error.attach error

  describe 'when instantiated', ->
    it 'should have an input port', ->
      chai.expect(c.inPorts.url).to.be.an 'object'
    it 'should have an output port', ->
      chai.expect(c.outPorts.dimensions).to.be.an 'object'

  describe 'with file system image', ->
    unless noflo.isBrowser()
      it 'should get dimensions of file system test image', (done) ->
        out.once 'data', (data) ->
          chai.expect(data).to.be.an 'object'
          chai.expect(data.width).to.equal 80
          chai.expect(data.height).to.equal 80
          done()
        ins.send 'spec/test-80x80.jpg'

  describe 'with remote test image', ->
    url = 'http://1.gravatar.com/avatar/40a5769da6d979c1ebc47cdec887f24a'
    it 'should have the correct group', (done) ->
      @timeout 10000
      out.once 'begingroup', (group) ->
        chai.expect(group).to.equal url
        done()
      ins.beginGroup url
      ins.send url
      ins.endGroup()
    it 'should find correct dimensions', (done) ->
      @timeout 10000
      error.once 'data', (data) ->
        console.log data
        chai.expect(true).to.equal false
        done()
      out.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.width).to.equal 80
        chai.expect(data.height).to.equal 80
        done()
      ins.send url

  describe 'with remote JPG image', ->
    url = 'http://s3.eu-central-1.amazonaws.com/bergie-iki-fi/flowhub-promo.jpg'
    it 'should have the correct group', (done) ->
      @timeout 10000
      out.once 'begingroup', (group) ->
        chai.expect(group).to.equal url
        done()
      ins.beginGroup url
      ins.send url
      ins.endGroup()
    it 'should find correct dimensions', (done) ->
      @timeout 10000
      error.once 'data', (data) ->
        console.log data
        chai.expect(true).to.equal false
        done()
      out.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.width).to.equal 770
        chai.expect(data.height).to.equal 376
        done()
      ins.send url
