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
  beforeEach ->
    c = Measure.getComponent()
    ins = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()
    c.inPorts.url.attach ins
    c.outPorts.dimensions.attach out

  describe 'when instantiated', ->
    it 'should have an input port', ->
      chai.expect(c.inPorts.url).to.be.an 'object'
    it 'should have an output port', ->
      chai.expect(c.outPorts.dimensions).to.be.an 'object'

  describe 'with file system image', ->
    unless noflo.isBrowser()
      it 'should get dimensions of file system test image', ->
        out.once 'data', (data) ->
          chai.expect(data).to.be.an 'array'
          chai.expect(data[0]).to.equal 80
          chai.expect(data[1]).to.equal 80
        ins.send 'spec/image-80x80.jpg'

  describe 'with remote test image', ->
    url = 'https://1.gravatar.com/avatar/40a5769da6d979c1ebc47cdec887f24a'
    it 'should have the correct group', ->
      out.once 'begingroup', (group) ->
        chai.expect(group).to.equal url
    it 'should find correct dimensions', ->
      out.once 'data', (data) ->
        chai.expect(data).to.be.an 'array'
        chai.expect(data[0]).to.equal 80
        chai.expect(data[1]).to.equal 81
      ins.send url
