noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  GetBorderlessBox = require '../components/GetBorderlessBox.coffee'
  testutils = require './testutils'
  http = require 'http'
  fs = require 'fs'
  async = require 'async'
else
  GetBorderlessBox = require 'noflo-image/components/GetBorderlessBox.js'
  testutils = require 'noflo-image/spec/testutils.js'

videos = [
  'https://www.youtube.com/watch?v=kQfF-P70V2Q'
  'https://www.youtube.com/watch?v=ukwdKX5Cmas'
  'https://www.youtube.com/watch?v=HCERNDg8ESY'
  'https://www.youtube.com/watch?v=sGbxmsDFVnE'
  'https://www.youtube.com/watch?v=WniCDigF6xo'
  'https://www.youtube.com/watch?v=c6bEs3dxjPg'
  'https://www.youtube.com/watch?v=0X9NFknjTRE'
  'https://www.youtube.com/watch?v=arTBU5cuBk8'
  'https://www.youtube.com/watch?v=O43hS6favvg'
  'https://www.youtube.com/watch?v=_0VDveYwbuU'
]

getVideoId = (video) ->
  return video.slice -11

buildThumbnailUrl = (id) ->
  return "http://i.ytimg.com/vi/#{id}/hqdefault.jpg"

downloadVideo = (video, filename, callback) ->
  id = getVideoId video
  uri = buildThumbnailUrl id
  request.get uri, (err, res) ->
    return callback err if err
    file = fs.createWriteStream filename
    stream = res.pipe file
    stream.on 'finish', callback

download = (url, dest, cb) ->
  file = fs.createWriteStream "spec/fixtures/#{dest}"
  console.log url, dest
  request = http.get url, (response) ->
    response.pipe file
    file.on 'finish', ->
      file.close cb
  request.on 'error', (err) ->
    fs.unlink dest
    if cb
      cb err.message

checkSimilar = (chai, bbox, expected, delta) ->
  chai.expect(bbox.x).to.be.closeTo expected.x, delta
  chai.expect(bbox.y).to.be.closeTo expected.y, delta
  chai.expect(bbox.width).to.be.closeTo expected.width, delta
  chai.expect(bbox.height).to.be.closeTo expected.height, delta

describe 'Video dataset', ->
  c = null
  canvas = null
  mean = null
  max = null
  avg = null
  out = null

  beforeEach ->
    c = GetBorderlessBox.getComponent()
    canvas = noflo.internalSocket.createSocket()
    mean = noflo.internalSocket.createSocket()
    max = noflo.internalSocket.createSocket()
    avg = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()

    c.inPorts.canvas.attach canvas
    c.inPorts.mean.attach mean
    c.inPorts.max.attach max
    c.inPorts.avg.attach avg
    c.outPorts.rectangle.attach out

  videos.forEach (video) ->
    describe "when passed", ->
      it 'should crop', (done) ->
        @timeout 10000
        out.once 'data', (res) ->
          filepath = "#{getVideoId(video)}.jpg"
          testutils.getCanvasWithImageNoShift filepath, (c) ->
            testutils.cropAndSave "cropped/#{getVideoId(video)}.png", c, res
            done()
          # checkSimilar chai, res, expected, 3

        inSrc = "#{getVideoId(video)}.jpg"
        download buildThumbnailUrl(getVideoId(video)), inSrc, ->
          testutils.getCanvasWithImageNoShift inSrc, (c) ->
            mean.send 2
            max.send 40
            canvas.send c
