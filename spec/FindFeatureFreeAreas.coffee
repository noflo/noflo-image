noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  FindFeatureFreeAreas = require '../components/FindFeatureFreeAreas.coffee'
else
  FindFeatureFreeAreas = require 'noflo-image/components/FindFeatureFreeAreas.js'

testutils = require './testutils'


describe 'FindFeatureFreeAreas', ->

  describe '.calculateStartingPoints()', ->
    describe 'when passing bounds and number of segments', ->
      it 'returns evenly spaced points', ->
        b = { w: 150, h: 200 }
        s = { x: 2, y: 3 }
        points = FindFeatureFreeAreas.calculateStartingPoints b, s
        chai.expect(points).to.be.an 'array'
        chai.expect(points).to.have.length 6
        chai.expect(points).to.deep.equal [
          {x:50, y:50}
          {x:50, y:100}
          {x:50, y:150}
          {x:100, y:50}
          {x:100, y:100}
          {x:100, y:150}
        ]

  describe '.spatialSortedIndices()', ->
    describe 'when given an unordered list of points', ->
      input = [
        {x:50, y:50}
        {x:100, y:100}
        {x:50, y:150}
        {x:100, y:50}
        {x:50, y:100}
        {x:100, y:150}
      ]
      indices = FindFeatureFreeAreas.spatialSortedIndices input
      it 'returns indices for X and Y axis', ->
        chai.expect(indices).to.be.an 'object'
        chai.expect(indices).to.have.property 'x'
        chai.expect(indices).to.have.property 'y'
      it 'X indices are sorted by X coordinates', ->
        chai.expect(indices.x).to.have.length 6
        values = (input[i].x for i in indices.x)
        chai.expect(values).to.deep.equal [ 50, 50, 50, 100, 100, 100 ]
        chai.expect(indices.x).to.deep.equal [ 0, 2, 4, 1, 3, 5 ]
      it 'Y indices are sorted by Y coordinates', ->
        chai.expect(indices.y).to.have.length 6
        values = (input[i].y for i in indices.y)
        chai.expect(values).to.deep.equal [ 50, 50, 100, 100, 150, 150 ]
        chai.expect(indices.y).to.deep.equal [ 0, 3, 1, 4, 2, 5 ]

  describe '.findIndexForPoint()', ->
    corners = [
      {x:50, y:50}
      {x:100, y:100}
      {x:50, y:150}
      {x:100, y:50}
      {x:50, y:100}
      {x:100, y:150}
    ]
    testcases = [ # r = results
      { n: 'middle', p: {x:70, y:110}, r: {x:2, y:3} }
      { n: 'left of', p: {x:10, y:70}, r: {x:-1, y:1} }
      { n: 'right of', p: {x:110, y:70}, r: {x:6, y:1} }
    ]
    indices = FindFeatureFreeAreas.spatialSortedIndices corners
    describe 'given corners and indices', ->
      it 'returns both X and Y axis', ->
        index = FindFeatureFreeAreas.findIndexForPoint corners, indices, { x: 70, y: 70 }
        chai.expect(index).to.be.an 'object'
        chai.expect(index).to.have.property 'x'
        chai.expect(index).to.have.property 'y'
    for testcase in testcases
      t = (test) ->
        describe "if point is #{test.n};", ->
          index = FindFeatureFreeAreas.findIndexForPoint corners, indices, test.p
          it "X index equals #{test.r.x}", ->
            chai.expect(index.x).to.equal test.r.x
          it "Y index equals #{test.r.y}", ->
            chai.expect(index.y).to.equal test.r.y
      t(testcase)

  describe '.growRectangle()', ->
    corners = [
      {x:10, y:10}
      {x:70, y:70}
      {x:30, y:33}
      {x:31, y:37}
      {x:54, y:159}
      {x:100, y:50}
      {x:56, y:140}
      {x:22, y:22}
    ]
    indices = FindFeatureFreeAreas.spatialSortedIndices corners
    bounds = { w: 100, h: 150 }
    point = { x: 70, y: 70 }
    threshold = 1
    describe 'when ran', ->
      region = FindFeatureFreeAreas.growRectangle corners, indices, point, bounds, threshold
      it 'returns region type', ->
        chai.expect(region).to.be.an 'object'
        chai.expect(region).to.have.property 'x'
        chai.expect(region).to.have.property 'y'
        chai.expect(region).to.have.property 'width'
        chai.expect(region).to.have.property 'height'
      it "x", ->
        chai.expect(region.x).to.equal 56
      it "y", ->
        chai.expect(region.y).to.equal 50
      it "width", ->
        chai.expect(region.width).to.equal 44
      it "height", ->
        chai.expect(region.height).to.equal 90



describe 'FindFeatureFreeAreas component', ->
  c = null
  ins = null
  corners = null
  areas = null
  beforeEach ->
    c = FindFeatureFreeAreas.getComponent()
    ins = noflo.internalSocket.createSocket()
    corners = noflo.internalSocket.createSocket()
    areas = noflo.internalSocket.createSocket()
    c.inPorts.corners.attach ins
    c.outPorts.corners.attach corners
    c.outPorts.areas.attach areas

  describe 'when instantiated', ->
    it 'should have an input port', ->
      chai.expect(c.inPorts.corners).to.be.an 'object'
    it 'should have output ports', ->
      chai.expect(c.outPorts.corners).to.be.an 'object'
      chai.expect(c.outPorts.areas).to.be.an 'object'
