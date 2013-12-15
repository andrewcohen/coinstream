log          = require('./lib/log')
db           = require('./lib/pg_connection')
PubNubFeed   = require('./lib/pubnub_feed')
FayeClient   = require('./lib/faye_client')
cluster      = require('cluster')
kue          = require('kue')

class App
  constructor: (options = {}) ->
    @jobs = kue.createQueue()

    if cluster.isMaster
      _workerCount = options["workers"] || require('os').cpus().length
      for cpu in [1.._workerCount]
        cluster.fork()
        log.info "Spawning worker"

      cluster.on 'exit', (worker) ->
        log.info "Worker [#{worker.id}] died"
        cluster.fork()

      if options["debug"]
        log.info "[#{new Date()}] initializing kue web ui"
        kue.app.listen(3001)

      faye   = new FayeClient()
      pubnub = new PubNubFeed()

      if options["ticker"]
        tickerJob = (message) =>
          @jobs.create('ticker', payload: message).save()
        pubnub.ticker(tickerJob)


      if options["depth"]
        depthJob = (message) =>
          @jobs.create('depth', payload: message).save()
        pubnub.depth(depthJob)
    else
      # this is gonna need promises
      # callback heLL
      if options["ticker"]
        @jobs.process 'ticker', (job, done) =>
          ticker = job.data.payload.ticker
          db.writeTicker ticker, ->
            FayeClient.publish('/ticker', {
              buy: ticker.buy.display_short,
              sell: ticker.sell.display_short,
              vol: ticker.vol.display_short
            }, ->
              log.info "Worker [#{cluster.worker.id}] | completed ticker [job #{job.id}] \n"
              done()
            )

      if options["depth"]
        @jobs.process 'depth', (job, done) =>
          db.writeDepth job.data.payload.depth , ->
            log.info "Worker [#{cluster.worker.id}] | completed depth [job #{job.id}] \n"
            done()



new App(
  debug: true
  ticker: true
  depth: true

  # defaults to # of cores
  #workers: 1
)
