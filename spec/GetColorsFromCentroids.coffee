noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
  testutils = require './testutils'
else
  baseDir = '/noflo-image'
  testutils = require 'noflo-image/spec/testutils.js'

describe 'GetColorsFromCentroids component', ->
  c = null
  ins = null
  paths = null
  out = null

  beforeEach (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'image/GetColorsFromCentroids', (err, instance) ->
      return done err if err
      c = instance
      ins = noflo.internalSocket.createSocket()
      paths = noflo.internalSocket.createSocket()
      out = noflo.internalSocket.createSocket()
      c.inPorts.canvas.attach ins
      c.inPorts.paths.attach paths
      c.outPorts.colors.attach out
      done()

  describe 'when instantiated', ->
    it 'should have input ports', ->
      chai.expect(c.inPorts.canvas).to.be.an 'object'
      chai.expect(c.inPorts.paths).to.be.an 'object'
    it 'should have output ports', ->
      chai.expect(c.outPorts.colors).to.be.an 'object'

  describe 'when passed a canvas and some paths', ->
    somePaths = [ 
      type: 'path'
      items: [
        { type: 'point', x: 100, y: 100}
        { type: 'point', x: 200, y: 50}
        { type: 'point', x: 200, y: 100}
      ]
    ]

    it 'should extract colors from the paths\' centroids', (done) ->
      @timeout 20000
      id = 1
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.eql [1]
        chai.expect(res.length).to.be.equal somePaths.length
        chai.expect(res[0]).to.equal 'rgb(0, 255, 255)'
        done()

      inSrc = 'colorful-octagon.png'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        ins.beginGroup id
        paths.send somePaths
        ins.send c
        ins.endGroup()
