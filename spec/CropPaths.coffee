noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  CropPaths = require '../components/CropPaths.coffee'
  testutils = require './testutils'
else
  CropPaths = require 'noflo-image/components/CropPaths.js'
  testutils = require 'noflo-image/spec/testutils.js'

describe 'CropPaths component', ->
  c = null
  ins = null
  reverse = null
  paths = null
  out = null

  beforeEach ->
    c = CropPaths.getComponent()
    ins = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()
    reverse = noflo.internalSocket.createSocket()
    paths = noflo.internalSocket.createSocket()

    c.inPorts.canvas.attach ins
    c.inPorts.paths.attach paths
    c.inPorts.reverse.attach reverse

    c.outPorts.out.attach out

  describe 'when instantiated', ->
    it 'should have input ports', ->
      chai.expect(c.inPorts.canvas).to.be.an 'object'
      chai.expect(c.inPorts.reverse).to.be.an 'object'
      chai.expect(c.inPorts.paths).to.be.an 'object'
    it 'should have output ports', ->
      chai.expect(c.outPorts.out).to.be.an 'object'

  describe 'when passed a canvas and some paths', ->
    data = {"saliency": {"bounding_rect": [[45, 218], [687, 639]],"bbox": {"x": 45, "y": 218, "width": 642, "height": 421},"confidence": 0.220515,"polygon": [[45, 548], [127, 548], [139, 536], [150, 533], [188, 538], [202, 555], [204, 596], [198, 608], [201, 629], [223, 638], [254, 631], [286, 595], [336, 586], [349, 568], [350, 547], [366, 530], [382, 529], [391, 535], [408, 526], [500, 523], [495, 513], [500, 492], [437, 495], [423, 490], [394, 490], [374, 495], [363, 492], [353, 480], [339, 477], [330, 466], [330, 452], [365, 409], [389, 400], [461, 408], [500, 403], [609, 407], [614, 388], [628, 376], [650, 371], [680, 375], [678, 356], [686, 338], [683, 333], [629, 325], [622, 318], [608, 283], [549, 272], [540, 261], [535, 232], [413, 219], [397, 227], [351, 232], [333, 250], [316, 253], [286, 243], [258, 218], [229, 218], [207, 234], [194, 267], [198, 303], [216, 332], [215, 351], [194, 433], [198, 451], [194, 469], [175, 489], [45, 496]], "center": [365, 443], "radius": 347.379, "regions": [{"polygon": [{"x": 45, "y": 548}, {"x": 127, "y": 548}, {"x": 139, "y": 536}, {"x": 150, "y": 533}, {"x": 188, "y": 538}, {"x": 202, "y": 555}, {"x": 204, "y": 596}, {"x": 198, "y": 608}, {"x": 201, "y": 629}, {"x": 223, "y": 638}, {"x": 254, "y": 631}, {"x": 286, "y": 595}, {"x": 336, "y": 586}, {"x": 349, "y": 568}, {"x": 350, "y": 547}, {"x": 366, "y": 530}, {"x": 382, "y": 529}, {"x": 391, "y": 535}, {"x": 408, "y": 526}, {"x": 500, "y": 523}, {"x": 495, "y": 513}, {"x": 500, "y": 492}, {"x": 437, "y": 495}, {"x": 423, "y": 490}, {"x": 394, "y": 490}, {"x": 374, "y": 495}, {"x": 363, "y": 492}, {"x": 353, "y": 480}, {"x": 339, "y": 477}, {"x": 330, "y": 466}, {"x": 330, "y": 452}, {"x": 365, "y": 409}, {"x": 389, "y": 400}, {"x": 461, "y": 408}, {"x": 500, "y": 403}, {"x": 609, "y": 407}, {"x": 614, "y": 388}, {"x": 628, "y": 376}, {"x": 650, "y": 371}, {"x": 680, "y": 375}, {"x": 678, "y": 356}, {"x": 686, "y": 338}, {"x": 683, "y": 333}, {"x": 629, "y": 325}, {"x": 622, "y": 318}, {"x": 608, "y": 283}, {"x": 549, "y": 272}, {"x": 540, "y": 261}, {"x": 535, "y": 232}, {"x": 413, "y": 219}, {"x": 397, "y": 227}, {"x": 351, "y": 232}, {"x": 333, "y": 250}, {"x": 316, "y": 253}, {"x": 286, "y": 243}, {"x": 258, "y": 218}, {"x": 229, "y": 218}, {"x": 207, "y": 234}, {"x": 194, "y": 267}, {"x": 198, "y": 303}, {"x": 216, "y": 332}, {"x": 215, "y": 351}, {"x": 194, "y": 433}, {"x": 198, "y": 451}, {"x": 194, "y": 469}, {"x": 175, "y": 489}, {"x": 45, "y": 496}], "center": {"x": 365, "y": 443}, "radius": 347.379, "bbox": {"x": 45, "y": 218, "width": 642, "height": 421}}]}}

    it 'should extract paths', (done) ->
      @timeout 20000
      id = 1
      groups = []
      out.once 'begingroup', (group) ->
        groups.push group
      out.once 'endgroup', (group) ->
        groups.pop()
      out.once 'data', (res) ->
        chai.expect(groups).to.eql [1]
        # testutils.writePNG 'bird_paths.png', res
        # chai.expect(res).to.be.an 'array'
        # chai.expect(res.length).to.be.equal someRects.length
        done()

      inSrc = 'bird.jpg'
      testutils.getCanvasWithImageNoShift inSrc, (c) ->
        ins.beginGroup id
        paths.send [data.saliency.regions[0].polygon]
        reverse.send false
        ins.send c
        ins.endGroup()
