noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
else
  baseDir = '/noflo-image'

describe 'ExtractColors graph', ->
  c = null
  ins = null
  out = null
  beforeEach (done) ->
    @timeout 10000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'image/ExtractColors', (instance) ->
      c = instance
      c.once 'ready', ->
        ins = noflo.internalSocket.createSocket()
        out = noflo.internalSocket.createSocket()
        c.inPorts.url.attach ins
        c.outPorts.colors.attach out
        done()

  describe 'with remote JPG image', ->
    url = 'http://farm8.staticflickr.com/7395/12952090783_ce023450da_b.jpg'
    unless noflo.isBrowser()
      it 'should have the correct group', ->
        out.once 'begingroup', (group) ->
          chai.expect(group).to.equal url
      it 'should find colors', (done) ->
        @timeout 10000
        out.once 'data', (data) ->
          chai.expect(data).to.be.an 'array'
          chai.expect(data[0]).to.be.an 'array'
          chai.expect(data[0].length).to.equal 3
          done()
        ins.send url
        ins.disconnect()

  describe 'with local JPG image', ->
    url = 'http://localhost:8000/spec/fixtures/extract.jpg'
    it 'should have the correct group', ->
      out.once 'begingroup', (group) ->
        chai.expect(group).to.equal url
    it 'should find colors', (done) ->
      @timeout 10000
      out.once 'data', (data) ->
        chai.expect(data).to.be.an 'array'
        chai.expect(data[0]).to.be.an 'array'
        chai.expect(data[0].length).to.equal 3
        done()
      ins.send url
      ins.disconnect()
