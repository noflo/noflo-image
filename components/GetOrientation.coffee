noflo = require 'noflo'

exports.getComponent = ->
  c = new noflo.Component
  c.description = 'Get orientation from image dimensions'

  c.inPorts.add 'dimensions',
    datatype: 'object'
    process: (event, packet) ->
      switch event
        when 'begingroup'
          c.outPorts.orientation.beginGroup packet
        when 'data'
          return unless packet.width or packet.height
          orientation = 'square'
          if packet.width > packet.height
            orientation = 'landscape'
          if packet.width < packet.height
            orientation = 'portrait'
          c.outPorts.orientation.send
            orientation: orientation
        when 'endgroup'
          c.outPorts.orientation.endGroup()
        when 'disconnect'
          c.outPorts.orientation.disconnect()

  c.outPorts.add 'orientation',
    datatype: 'object'

  c

