noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
else
  baseDir = '/noflo-image'

describe 'UrlToCanvas graph', ->
  c = null
  ins = null
  out = null
  beforeEach (done) ->
    @timeout 10000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'image/UrlToCanvas', (err, instance) ->
      c = instance
      c.once 'ready', ->
        ins = noflo.internalSocket.createSocket()
        out = noflo.internalSocket.createSocket()
        c.inPorts.url.attach ins
        c.outPorts.canvas.attach out
        done()

  describe 'with remote JPG image', ->
    url = 'http://farm8.staticflickr.com/7395/12952090783_ce023450da_b.jpg'
    it 'should have the correct group', (done) ->
      @timeout 10000
      out.once 'begingroup', (group) ->
        chai.expect(group).to.equal url
        done()
      ins.send url
      ins.disconnect()
    it 'should make a canvas with the correct size', (done) ->
      @timeout 10000
      out.once 'data', (data) ->
        chai.expect(data.width).to.equal 1024
        chai.expect(data.height).to.equal 768
        done()
      ins.send url
      ins.disconnect()

  describe.skip 'with local JPG image', ->
    url = 'http://localhost:8000/spec/fixtures/extract.jpg'
    it 'should have the correct group', (done) ->
      out.once 'begingroup', (group) ->
        chai.expect(group).to.equal url
        done()
      ins.send url
      ins.disconnect()
    it 'should make a canvas with the correct size', (done) ->
      @timeout 10000
      out.once 'data', (data) ->
        chai.expect(data.width).to.equal 1024
        chai.expect(data.height).to.equal 768
        done()
      ins.send url
      ins.disconnect()
