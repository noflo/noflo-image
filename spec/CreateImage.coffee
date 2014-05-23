noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  CreateImage = require '../components/CreateImage-node.coffee'
else
  CreateImage = require 'noflo-image/components/CreateImage.js'

describe 'CreateImage component', ->
  c = null
  ins = null
  out = null
  error = null
  beforeEach ->
    c = CreateImage.getComponent()
    ins = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()
    error = noflo.internalSocket.createSocket()
    c.inPorts.url.attach ins
    c.outPorts.image.attach out
    c.outPorts.error.attach error

  describe 'when instantiated', ->
    it 'should have an input port', ->
      chai.expect(c.inPorts.url).to.be.an 'object'
    it 'should have an output port', ->
      chai.expect(c.outPorts.image).to.be.an 'object'

  describe 'with file system image', ->
    unless noflo.isBrowser()
      it 'should make image from file system test image', (done) ->
        out.once 'data', (data) ->
          chai.expect(data).to.be.an 'object'
          chai.expect(data.width).to.equal 80
          chai.expect(data.height).to.equal 80
          done()
        ins.send 'spec/test-80x80.jpg'

  describe 'with remote test image', ->
    url = 'https://1.gravatar.com/avatar/40a5769da6d979c1ebc47cdec887f24a'
    it 'should have the correct group', (done) ->
      out.once 'begingroup', (group) ->
        chai.expect(group).to.equal url
        done()
      ins.send url
    it 'should find correct dimensions', (done) ->
      @timeout 0
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
    url = 'http://bergie.iki.fi/files/flowhub-promo.jpg'
    it 'should have the correct group', (done) ->
      out.once 'begingroup', (group) ->
        chai.expect(group).to.equal url
        done()
      ins.send url
    it 'should find correct dimensions', (done) ->
      @timeout 0
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
