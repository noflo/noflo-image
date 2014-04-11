noflo = require 'noflo'

# Recursive function for calculating greatest common divisor
gcd = (a, b) -> (if (b is 0) then a else gcd(b, a % b))

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Calculate aspect ratio from image dimensions'

  c.inPorts.add 'dimensions',
    datatype: 'object'
    process: (event, packet) ->
      switch event
        when 'begingroup'
          c.outPorts.ratio.beginGroup packet
        when 'data'
          return unless packet.width or packet.height
          divisor = gcd packet.width, packet.height
          c.outPorts.ratio.send
            ratio: "#{packet.width/divisor}:#{packet.height/divisor}"
        when 'endgroup'
          c.outPorts.ratio.endGroup()
        when 'disconnect'
          c.outPorts.ratio.disconnect()

  c.outPorts.add 'ratio',
    datatype: 'object'

  c
