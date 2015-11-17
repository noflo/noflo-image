noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  ApplyVignette = require '../components/ApplyVignette.coffee'
  testutils = require './testutils'
else
  ApplyVignette = require 'noflo-image/components/ApplyVignette.js'
  testutils = require 'noflo-image/spec/testutils.js'
 
 
describe 'ApplyVignette component', ->
 
  c = null
  inImage = null
  outImage = null

  beforeEach ->
    c = ApplyVignette.getComponent()
    inImage = noflo.internalSocket.createSocket()
    outImage = noflo.internalSocket.createSocket()
    c.inPorts.canvas.attach inImage
    c.outPorts.canvas.attach outImage
 
  describe 'when instantiated', ->
    it 'should have one input port', ->
      chai.expect(c.inPorts.canvas).to.be.an 'object'
    it 'should have one output port', ->
      chai.expect(c.outPorts.canvas).to.be.an 'object'
 
  describe 'with file system image', ->
    it 'should make an image with a dark vignette', (done) ->
      id = null
      groups = []
      outImage.once 'begingroup', (group) ->
        groups.push group
      outImage.once 'data', (res) ->
        chai.expect(res).to.be.an 'object'

        # Tests result versus reference data
        refSrc = 'vignette.png'
        idOut = testutils.getCanvasWithImageNoShift refSrc, (ref) =>
          resCtx = res.getContext '2d'
          resData = resCtx.getImageData(0, 0, res.width, res.height).data
          
          refCtx = ref.getContext '2d'
          refData = refCtx.getImageData(0, 0, ref.width, ref.height).data
          testutils.writePNG 'vignette.out.png', res
          
          for x in [0...resData.length] by 4
            difference = Math.abs(refData[x]-resData[x])
            threshold = 2.5
            chai.expect(difference).to.be.at.most threshold
          done()

      inSrc = 'original.jpg'
      id = testutils.getCanvasWithImageNoShift inSrc, (image) ->
        inImage.beginGroup id
        inImage.send image
        inImage.endGroup()