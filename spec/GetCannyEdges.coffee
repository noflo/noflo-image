noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  GetCannyEdges = require '../components/GetCannyEdges.coffee'
  testutils = require './testutils'
else
  GetCannyEdges = require 'noflo-image/components/GetCannyEdges.js'
  testutils = require 'noflo-image/spec/testutils.js'


describe 'GetCannyEdges component', ->

  c = null
  inCanvas = null
  low = null
  high = null
  kernel = null
  outCanvas = null
  beforeEach ->
    c = GetCannyEdges.getComponent()
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

  describe 'when instantiated', ->
    it 'should have four input ports', ->
      chai.expect(c.inPorts.canvas).to.be.an 'object'
      chai.expect(c.inPorts.low).to.be.an 'object'
      chai.expect(c.inPorts.high).to.be.an 'object'
      chai.expect(c.inPorts.kernel).to.be.an 'object'
    it 'should have one output port', ->
      chai.expect(c.outPorts.canvas).to.be.an 'object'