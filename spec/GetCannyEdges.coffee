noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
else
  baseDir = '/noflo-image'

describe 'GetCannyEdges component', ->
  c = null
  inCanvas = null
  low = null
  high = null
  kernel = null
  outCanvas = null
  beforeEach (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'image/GetCannyEdges', (err, instance) ->
      return done err if err
      c = instance
      inCanvas = noflo.internalSocket.createSocket()
      low = noflo.internalSocket.createSocket()
      high = noflo.internalSocket.createSocket()
      kernel = noflo.internalSocket.createSocket()
      outCanvas = noflo.internalSocket.createSocket()
      c.inPorts.canvas.attach inCanvas
      c.inPorts.low.attach low
      c.inPorts.high.attach high
      c.inPorts.kernel.attach kernel
      c.outPorts.canvas.attach outCanvas
      done()

  describe 'when instantiated', ->
    it 'should have four input ports', ->
      chai.expect(c.inPorts.canvas).to.be.an 'object'
      chai.expect(c.inPorts.low).to.be.an 'object'
      chai.expect(c.inPorts.high).to.be.an 'object'
      chai.expect(c.inPorts.kernel).to.be.an 'object'
    it 'should have one output port', ->
      chai.expect(c.outPorts.canvas).to.be.an 'object'
