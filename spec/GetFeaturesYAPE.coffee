noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  path = require 'path'
  baseDir = path.resolve __dirname, '../'
  testutils = require './testutils'
else
  baseDir = '/noflo-image'
  testutils = require 'noflo-image/spec/testutils.js'

describe 'GetFeaturesYAPE component', ->
  c = null
  ins = null
  corners = null
  canvas = null
  beforeEach (done) ->
    @timeout 4000
    loader = new noflo.ComponentLoader baseDir
    loader.load 'image/GetFeaturesYAPE', (err, instance) ->
      c = instance
      ins = noflo.internalSocket.createSocket()
      corners = noflo.internalSocket.createSocket()
      canvas = noflo.internalSocket.createSocket()
      c.inPorts.canvas.attach ins
      c.outPorts.corners.attach corners
      c.outPorts.canvas.attach canvas
      done()

  describe 'when instantiated', ->
    it 'should have an input port', ->
      chai.expect(c.inPorts.canvas).to.be.an 'object'
    it 'should have output ports', ->
      chai.expect(c.outPorts.corners).to.be.an 'object'
      chai.expect(c.outPorts.canvas).to.be.an 'object'

  testcases = [
    'textAnywhere/flickr-3178100324-original_small.jpg'
    'noText/flickr-8132786781-small.jpg'
    'textRegion/3010029968_02742a1aec_b.jpg'
  ]

  testcases.pop() if noflo.isBrowser()

  for testcase in testcases
      describe testcase, ->
          describe 'when passed a canvas', ->
            @timeout 3000
            input = testcase
            ref = testcase+'.corners.json'
            expected = (testutils.getData ref, {corners: []}).corners
            it 'should extract corners', (done) ->
              id = null
              groups = []
              corners.once "begingroup", (group) ->
                groups.push group
              corners.once "data", (corners) ->
                testutils.writeOut ref+'.out', { corners: corners }
                chai.expect(corners[0]).to.have.property 'x'
                chai.expect(corners[0]).to.have.property 'y'
                chai.expect(corners[0]).to.have.property 'score'
                chai.expect(corners[0]).to.have.property 'level'
                unless noflo.isBrowser()
                  chai.expect(corners.length).to.be.within expected.length-2000, expected.length+2000
                  #chai.expect(corners.slice(0,100)).to.deep.equal expected.slice 0, 100
                chai.expect(groups).to.have.length 1
                chai.expect(groups[0]).to.equal id
                done()
              id = testutils.getCanvasWithImage input, (canvas) ->
                ins.beginGroup id
                ins.send canvas
                ins.endGroup()

            it 'should send canvas out', (done) ->
              id = null
              groups = []
              canvas.once "begingroup", (group) ->
                groups.push group
              canvas.once "data", (canvas) ->
                chai.expect(groups).to.have.length 1
                chai.expect(groups[0]).to.equal id
                done()
              id = testutils.getCanvasWithImage input, (canvas) ->
                ins.beginGroup id
                ins.send canvas
                ins.endGroup()
