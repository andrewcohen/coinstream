log  = require('./log')
http = require('http')
faye = require('faye')
client = new faye.Client('http://localhost:8000/faye')

class FayeClient
  constructor: (options = {}) ->
    server = http.createServer (req, res) ->
      res.writeHead(200, {'Content-Type': 'text/plain'})
      res.write('Hi, non bayeux req')
      res.end()

    bayeux = new faye.NodeAdapter(mount: '/faye', timeout: 45)
    bayeux.attach(server)

    bayeux.on 'handshake', (a) -> log.info "#{a} connected"
    bayeux.on 'subscribe', (a, b) -> log.info "#{a} subscribed to #{b}"
    bayeux.on 'disconnect', (a) -> log.info "#{a} disconnected"

    server.listen(8000)

  @publish: (channel, payload, cb) ->
    client.publish(channel, payload)
    cb()



module.exports = FayeClient
