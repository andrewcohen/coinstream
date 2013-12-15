log          = require('./lib/log')
db           = require('./lib/pg_connection')
PubNubFeed   = require('./lib/pubnub_feed')
cluster      = require('cluster')
kue          = require('kue')

# outbound ws
http = require('http')
faye = require('faye')


server = http.createServer (req, res) ->
  res.writeHead(200, {'Content-Type': 'text/plain'})
  res.write('Hi, non bayeux req')
  res.end()

bayeux = new faye.NodeAdapter(mount: '/faye', timeout: 45)
bayeux.attach(server)

bayeux.on 'handshake', (a) -> log.info "#{a} connected"
bayeux.on 'subscribe', (a, b) -> log.info "#{a} subscribed to #{b}"
bayeux.on 'disconnect', (a) -> log.info "#{a} disconnected"

client = new faye.Client('http://localhost:8000/faye')

class App
  constructor: (options = {}) ->
    #if options["debug"]
      #log.info "[#{new Date()}] initializing kue web ui"
      #kue.app.listen(3001)

    # set up kue
    @jobs = kue.createQueue()

    if cluster.isMaster
      _workerCount = options["workers"] || require('os').cpus().length
      for cpu in [1.._workerCount]
        cluster.fork()
        log.info "Spawning worker"

      cluster.on 'exit', (worker) ->
        log.info "Worker [#{worker.id}] died"
        cluster.fork()

      # set up faye
      server.listen(8000)

      # set up pubnub
      @pubnub = new PubNubFeed()

      tickerJob = (message) =>
        @jobs.create('ticker', payload: message).save()

      @pubnub.ticker(tickerJob)

    else
      @jobs.process 'ticker', (job, done) =>
        ticker = job.data.payload.ticker
        db.writeTicker(ticker)

        client.publish('/ticker', {
          buy: ticker.buy.display_short,
          sell: ticker.sell.display_short,
          ticker: JSON.stringify ticker
        })

        log.info "Worker [#{cluster.worker.id}] | [#{job.id}] completed"
        done()


new App(
  debug: true

  # defaults to # of cores
  #workers: 1
)
