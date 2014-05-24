noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  GetFeaturesYAPE = require '../components/GetFeaturesYAPE.coffee'
else
  GetFeaturesYAPE = require 'noflo-canvas/components/GetFeaturesYAPE.js'

testutils = require './testutils'

describe 'GetFeaturesYAPE component', ->
  c = null
  ins = null
  corners = null
  canvas = null
  beforeEach ->
    c = GetFeaturesYAPE.getComponent()
    ins = noflo.internalSocket.createSocket()
    corners = noflo.internalSocket.createSocket()
    canvas = noflo.internalSocket.createSocket()
    c.inPorts.canvas.attach ins
    c.outPorts.corners.attach corners
    c.outPorts.canvas.attach canvas

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
  for testcase in testcases

      describe testcase, ->
          describe 'when passed a canvas', ->
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
                chai.expect(corners).to.be.an 'array'
                chai.expect(corners.length).to.be.within expected.length-1, expected.length+1
                chai.expect(corners[0]).to.be.an 'object'
                chai.expect(corners[0]).to.have.property 'x'
                chai.expect(corners[0]).to.have.property 'y'
                chai.expect(corners[0]).to.have.property 'score'
                chai.expect(corners[0]).to.have.property 'level'
                chai.expect(corners.slice(0,100)).to.deep.equal expected.slice 0, 100
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
                chai.expect(canvas).to.be.an 'object'
                chai.expect(groups).to.have.length 1
                chai.expect(groups[0]).to.equal id
                done()
              id = testutils.getCanvasWithImage input, (canvas) ->
                ins.beginGroup id
                ins.send canvas
                ins.endGroup()
