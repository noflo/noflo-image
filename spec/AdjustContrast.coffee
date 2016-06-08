noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  AdjustContrast = require '../components/AdjustContrast.coffee'
  testutils = require './testutils'
else
  AdjustContrast = require 'noflo-image/components/AdjustContrast.js'
  testutils = require 'noflo-image/spec/testutils.js'


describe 'AdjustContrast component', ->

  c = null
  inImage = null
  level = null
  outImage = null

  beforeEach ->
    c = AdjustContrast.getComponent()
    inImage = noflo.internalSocket.createSocket()
    level = noflo.internalSocket.createSocket()
    outImage = noflo.internalSocket.createSocket()
    c.inPorts.canvas.attach inImage
    c.inPorts.level.attach level
    c.outPorts.canvas.attach outImage

  describe 'when instantiated', ->
    it 'should have two input ports', ->
      chai.expect(c.inPorts.canvas).to.be.an 'object'
      chai.expect(c.inPorts.level).to.be.an 'object'
    it 'should have one output port', ->
      chai.expect(c.outPorts.canvas).to.be.an 'object'

  describe 'with file system image', ->
    it 'should make an image with adjusted contrast', (done) ->
      id = null
      groups = []
      outImage.once 'begingroup', (group) ->
        groups.push group
      outImage.once 'data', (res) ->
        chai.expect(res).isObject

        # Tests result versus reference data
        refSrc = 'contrast.png'
        idOut = testutils.getCanvasWithImageNoShift refSrc, (ref) =>
          resCtx = res.getContext '2d'
          resData = resCtx.getImageData(0, 0, res.width, res.height).data
          refCtx = ref.getContext '2d'
          refData = refCtx.getImageData(0, 0, ref.width, ref.height).data
          for x in [0...resData.length] by 4
            difference = Math.abs(refData[x]-resData[x])
            threshold = 1.5
            chai.expect(difference).to.be.at.most threshold
          done()

      inSrc = 'original.jpg'
      id = testutils.getCanvasWithImageNoShift inSrc, (image) ->
        inImage.beginGroup id
        inImage.send image
        inImage.endGroup()
