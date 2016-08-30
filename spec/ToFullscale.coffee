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
    @timeout 50000
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
      @timeout 5*1000
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
      it 'should return correct URL for downloading original', (done) ->
        newUrl.on 'data', (image) ->
          chai.expect(image).to.equal 'https://farm4.staticflickr.com/3493/3961596996_c9fb5c5e00_o.png'
          done()
        url.send 'https://farm4.staticflickr.com/3493/3961596996_c9fb5c5e00_o_d.png'
      it 'should return the same URL for and old image', (done) ->
        newUrl.on 'data', (image) ->
          chai.expect(image).to.equal 'https://farm4.staticflickr.com/3493/3961596996_367327afd9.jpg'
          done()
        url.send 'https://farm4.staticflickr.com/3493/3961596996_367327afd9.jpg'

    describe 'with WordPress.com images', ->
      it 'should return correct URL for non-sized', (done) ->
        newUrl.on 'data', (image) ->
          chai.expect(image).to.equal 'http://tctechcrunch2011.files.wordpress.com/2013/07/henri-bergius3.jpg'
          done()
        url.send 'http://tctechcrunch2011.files.wordpress.com/2013/07/henri-bergius3.jpg'
      it 'should return correct URL for thumbnails', (done) ->
        newUrl.on 'data', (image) ->
          chai.expect(image).to.equal 'http://tctechcrunch2011.files.wordpress.com/2013/07/henri-bergius3.jpg'
          done()
        url.send 'http://tctechcrunch2011.files.wordpress.com/2013/07/henri-bergius3.jpg?w=400'


    describe 'with a small variant', ->
      return if noflo.isBrowser()
      it 'should return fullscale URL when one exists', (done) ->
        newUrl.on 'data', (image) ->
          chai.expect(image).to.equal 'http://s3.eu-central-1.amazonaws.com/bergie-iki-fi/ingress-table-test.jpg'
          done()
        url.send 'http://s3.eu-central-1.amazonaws.com/bergie-iki-fi/ingress-table-test-small.jpg'
      it 'should return thumbnail URL when one doesn\'t exist', (done) ->
        newUrl.on 'data', (image) ->
          chai.expect(image).to.equal 'http://bergie.iki.fi/files/deathmonkey-map-small.jpg'
          done()
        url.send 'http://bergie.iki.fi/files/deathmonkey-map-small.jpg'

    describe 'with Wikimedia Commons thumbnails', ->
      it 'should return correct URL for non-sized', (done) ->
        newUrl.on 'data', (image) ->
          chai.expect(image).to.equal 'http://upload.wikimedia.org/wikipedia/commons/7/7a/India_-_Varanasi_green_peas_-_2714.jpg'
          done()
        url.send 'http://upload.wikimedia.org/wikipedia/commons/7/7a/India_-_Varanasi_green_peas_-_2714.jpg'
      it 'should return correct URL for thumbnails', (done) ->
        newUrl.on 'data', (image) ->
          chai.expect(image).to.equal 'http://upload.wikimedia.org/wikipedia/commons/7/7a/India_-_Varanasi_green_peas_-_2714.jpg'
          done()
        url.send 'http://upload.wikimedia.org/wikipedia/commons/thumb/7/7a/India_-_Varanasi_green_peas_-_2714.jpg/700px-India_-_Varanasi_green_peas_-_2714.jpg'
      it 'should return correct URL for thumbnails with escaped characters', (done) ->
        newUrl.on 'data', (image) ->
          chai.expect(image).to.equal 'http://upload.wikimedia.org/wikipedia/commons/1/1f/Vistas_desde_la_iglesia_de_San_Pedro%2C_Riga%2C_Letonia%2C_2012-08-07%2C_DD_01.JPG'
          done()
        url.send 'http://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/Vistas_desde_la_iglesia_de_San_Pedro%2C_Riga%2C_Letonia%2C_2012-08-07%2C_DD_01.JPG/1000px-Vistas_desde_la_iglesia_de_San_Pedro%2C_Riga%2C_Letonia%2C_2012-08-07%2C_DD_01.JPG'

    describe 'with imgflo urls', ->
      it 'should return URL unchanged when not a processing request', (done) ->
        newUrl.on 'data', (image) ->
          chai.expect(image).to.equal 'http://imgflo.herokuapp.com/'
          done()
        url.send 'http://imgflo.herokuapp.com/'
      it 'should return URL unchanged when no input param', (done) ->
        newUrl.on 'data', (image) ->
          chai.expect(image).to.equal 'https://imgflo.herokuapp.com/graph/vahj1ThiexotieMo/fe974927812464bdb942e2ce8d03c9fb/canvas?width=150'
          done()
        url.send 'https://imgflo.herokuapp.com/graph/vahj1ThiexotieMo/fe974927812464bdb942e2ce8d03c9fb/canvas?width=150'
      it 'should return input URL for gradientmap', (done) ->
        newUrl.on 'data', (image) ->
          chai.expect(image).to.equal 'http://i.huffpost.com/gen/2211142/thumbs/o-ELON-MUSK-facebook.jpg'
          done()
        url.send 'https://imgflo.herokuapp.com/graph/vahj1ThiexotieMo/fb5e9435a73ca48b11618a773e40389e/gradientmap.jpg?input=http%3A%2F%2Fi.huffpost.com%2Fgen%2F2211142%2Fthumbs%2Fo-ELON-MUSK-facebook.jpg&width=2000&height=1000&stop1=0&stop2=1&color1=%235a858c&color2=%2370ccc7&opacity=1&srgb=True'

    describe 'with gravatar.com urls', ->
      it 'should return URL unchanged when not an avatar', (done) ->
        newUrl.on 'data', (image) ->
          chai.expect(image).to.equal 'https://en.gravatar.com/images/support-matts-profile.png'
          done()
        url.send 'https://en.gravatar.com/images/support-matts-profile.png'
      it 'should modify s parameter for avatars', (done) ->
        newUrl.on 'data', (image) ->
          chai.expect(image).to.equal 'http://1.gravatar.com/avatar/ad3c9298254a01276827a5ad9485181b?s=512&d=mm&r=g'
          done()
        url.send 'http://1.gravatar.com/avatar/ad3c9298254a01276827a5ad9485181b?s=48&d=mm&r=g'
      it 'should modify size parameter for avatars', (done) ->
        newUrl.on 'data', (image) ->
          chai.expect(image).to.equal 'http://www.gravatar.com/avatar/205e460b479e2e5b48aec07710c08d50?size=512'
          done()
        url.send 'http://www.gravatar.com/avatar/205e460b479e2e5b48aec07710c08d50?size=200'
      it 'should add size parameter for avatar if not existing', (done) ->
        newUrl.on 'data', (image) ->
          chai.expect(image).to.equal 'http://www.gravatar.com/avatar/205e460b479e2e5b48aec07710c08d50?size=512'
          done()
        url.send 'http://www.gravatar.com/avatar/205e460b479e2e5b48aec07710c08d50'
