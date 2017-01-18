noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
  testutils = require './testutils'
else
  baseDir = '/noflo-image'
  testutils = require 'noflo-image/spec/testutils.js'

describe 'ExtractSaturation component', ->
  c = null
  ins = null
  paths = null
  out = null
  beforeEach (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'image/ExtractSaturation', (err, instance) ->
      return done err if err
      c = instance
      ins = noflo.internalSocket.createSocket()
      out = noflo.internalSocket.createSocket()
      c.inPorts.canvas.attach ins
      c.outPorts.saturation.attach out
      done()

  describe 'when instantiated', ->
    it 'should have input ports', ->
      chai.expect(c.inPorts.canvas).to.be.an 'object'
    it 'should have output ports', ->
      chai.expect(c.outPorts.saturation).to.be.an 'object'

  describe 'when passed a canvas', ->
    it 'should extract global saturation', (done) ->
      id = 1
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.eql [1]
        done()

      inSrc = 'original.jpg'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        ins.beginGroup id
        ins.send c
        ins.endGroup()

  describe 'when passed a saturated canvas', ->
    it 'should extract high saturation level', (done) ->
      id = 1
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.eql [1]
        chai.expect(res).to.be.gte 0
        done()

      inSrc = 'saturation.png'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        ins.beginGroup id
        ins.send c
        ins.endGroup()

  describe 'when passed a muted canvas', ->
    it 'should extract low saturation level', (done) ->
      id = 1
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.eql [1]
        chai.expect(res).to.be.lte 0
        done()

      inSrc = 'muted.png'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        ins.beginGroup id
        ins.send c
        ins.endGroup()
