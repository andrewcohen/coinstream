log          = require('./lib/log')
db           = require('./lib/pg_connection')
PubNubFeed   = require('./lib/pubnub_feed')
FayeClient   = require('./lib/faye_client')
cluster      = require('cluster')
kue          = require('kue')

class App
  constructor: (options = {}) ->
    #if options["debug"]
      #log.info "[#{new Date()}] initializing kue web ui"
      #kue.app.listen(3001)

    @jobs = kue.createQueue()

    if cluster.isMaster
      _workerCount = options["workers"] || require('os').cpus().length
      for cpu in [1.._workerCount]
        cluster.fork()
        log.info "Spawning worker"

      cluster.on 'exit', (worker) ->
        log.info "Worker [#{worker.id}] died"
        cluster.fork()

      faye   = new FayeClient()
      pubnub = new PubNubFeed()

      tickerJob = (message) =>
        @jobs.create('ticker', payload: message).save()

      # subscribe to ticker channel with callback tickerJob
      pubnub.ticker(tickerJob)

    else
      # this is gonna need promises
      # callback heLL
      @jobs.process 'ticker', (job, done) =>
        ticker = job.data.payload.ticker
        db.writeTicker ticker, ->
          FayeClient.publish('/ticker', {
            buy: ticker.buy.display_short,
            sell: ticker.sell.display_short,
            vol: ticker.vol.display_short
          }, ->
            log.info "Worker [#{cluster.worker.id}] | completed [job #{job.id}] \n"
            done()
          )



new App(
  debug: true

  # defaults to # of cores
  #workers: 1
)
