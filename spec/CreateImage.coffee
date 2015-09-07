noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  CreateImage = require '../components/CreateImage-node.coffee'
else
  CreateImage = require 'noflo-image/components/CreateImage.js'

describe 'CreateImage component', ->
  c = null
  ins = null
  sock_cors = null
  out = null
  error = null
  beforeEach ->
    c = CreateImage.getComponent()
    ins = noflo.internalSocket.createSocket()
    sock_cors = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()
    error = noflo.internalSocket.createSocket()
    c.inPorts.url.attach ins
    c.inPorts.crossorigin.attach sock_cors
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
      it 'should send an error for zero-sized images', (done) ->
        error.once 'data', (data) ->
          chai.expect(data).to.be.an 'object'
          chai.expect(data.url).to.equal 'spec/empty.jpg'
          done()
        ins.send 'spec/empty.jpg'

  describe 'with remote test image', ->
    url = 'http://1.gravatar.com/avatar/40a5769da6d979c1ebc47cdec887f24a'
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
    @timeout 4000
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

  describe 'with missing remote image', ->
    return if noflo.isBrowser()
    url = 'http://bergie.iki.fi/files/this-file-doesnt-exist-promo.jpg'
    it 'should do a correct error', (done) ->
      @timeout 0
      error.once 'data', (data) ->
        chai.expect(data.url).to.equal url
        done()
      ins.send url

  if noflo.isBrowser()

    describe 'with CORS-served image', ->
      it 'should be cors-enabled', (done) ->
        url = 'http://i.meemoo.me/v1/out/gf06kZyrQW6DWmwMf5zp_meemoo.png'
        sock_cors.send 'Anonymous'
        out.once 'data', (data) ->
          chai.expect(data).to.be.an 'object'
          done()
        ins.send url
      # it 'should error', (done) ->
      #   url = 'http://meemoo.org/hack-our-apps/shots/monochrome.png'
      #   sock_cors.send 'Anonymous'
      #   error.once 'data', (data) ->
      #     chai.expect(data).to.be.an 'object'
      #     done()
      #   ins.send url
