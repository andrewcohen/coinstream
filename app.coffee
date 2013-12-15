log          = require('./lib/log')
pgConnection = require('./lib/pg_connection')
PubNubFeed   = require('./lib/pubnub_feed')
cluster      = require('cluster')
kue          = require('kue')

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

      # set up pubnub
      @pubnub = new PubNubFeed()

      tickerJob = (message) =>
        @jobs.create('ticker', payload: message).save()

      @pubnub.ticker(tickerJob)

    else
      @jobs.process 'ticker', (job, done) =>
        pgConnection.writeTicker(job.data.payload)
        #push to rails via ws
        #
        log.info "Worker [#{cluster.worker.id}] | [#{job.id}] completed"
        done()


new App(
  debug: true

  # defaults to # of cores
  #workers: 1
)
