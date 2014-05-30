noflo = require 'noflo'
unless noflo.isBrowser()
  chai = require 'chai' unless chai
  ToFullscale = require '../components/ToFullscale.coffee'
else
  ToFullscale = require 'noflo-image/components/ToFullscale.js'

describe 'ToFullscale component', ->
  c = null
  url = null
  newUrl = null
  error = null
  beforeEach ->
    c = ToFullscale.getComponent()
    url = noflo.internalSocket.createSocket()
    newUrl = noflo.internalSocket.createSocket()
    error = noflo.internalSocket.createSocket()
    c.inPorts.url.attach url
    c.outPorts.url.attach newUrl

  describe 'getting fullscale URLs', ->
    describe 'with random online images', ->
      it 'shouldn\'t touch the URL', (done) ->
        newUrl.on 'data', (image) ->
          chai.expect(image).to.equal 'http://www.esa.int/var/esa/storage/images/esa_multimedia/images/2014/04/glowing_jewels_in_the_galactic_plane/14491843-1-eng-GB/Glowing_jewels_in_the_Galactic_Plane.jpg'
          done()
        url.send 'http://www.esa.int/var/esa/storage/images/esa_multimedia/images/2014/04/glowing_jewels_in_the_galactic_plane/14491843-1-eng-GB/Glowing_jewels_in_the_Galactic_Plane.jpg'

    describe 'with Flickr images', ->
      it 'should return correct URL for non-sized', (done) ->
        newUrl.on 'data', (image) ->
          chai.expect(image).to.equal 'https://farm8.staticflickr.com/7395/12952090783_ce023450da_b.jpg'
          done()
        url.send 'https://farm8.staticflickr.com/7395/12952090783_ce023450da.jpg'
      it 'should return correct URL for square', (done) ->
        newUrl.on 'data', (image) ->
          chai.expect(image).to.equal 'https://farm8.staticflickr.com/7395/12952090783_ce023450da_b.jpg'
          done()
        url.send 'https://farm8.staticflickr.com/7395/12952090783_ce023450da_s.jpg'
      it 'should return correct URL for large', (done) ->
        newUrl.on 'data', (image) ->
          chai.expect(image).to.equal 'https://farm8.staticflickr.com/7395/12952090783_ce023450da_b.jpg'
          done()
        url.send 'https://farm8.staticflickr.com/7395/12952090783_ce023450da_b.jpg'
      it 'should return correct URL for original', (done) ->
        newUrl.on 'data', (image) ->
          chai.expect(image).to.equal 'https://farm8.staticflickr.com/7395/12952090783_65a0f60fd9_o.jpg'
          done()
        url.send 'https://farm8.staticflickr.com/7395/12952090783_65a0f60fd9_o.jpg'

    describe 'with a small variant', ->
      return if noflo.isBrowser()
      it 'should return fullscale URL when one exists', (done) ->
        newUrl.on 'data', (image) ->
          chai.expect(image).to.equal 'http://bergie.iki.fi/files/ingress-table-test.jpg'
          done()
        url.send 'http://bergie.iki.fi/files/ingress-table-test-small.jpg'
      it 'should return thumbnail URL when one doesn\'t exist', (done) ->
        newUrl.on 'data', (image) ->
          chai.expect(image).to.equal 'http://bergie.iki.fi/files/deathmonkey-map-small.jpg'
          done()
        url.send 'http://bergie.iki.fi/files/deathmonkey-map-small.jpg'
