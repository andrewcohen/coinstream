cluster      = require('cluster')
pubnub       = require('pubnub')
kue          = require('kue')
jobs         = kue.createQueue()
pgConnection = require('./lib/pg_connection')

class App
  constructor: (options = {}) ->
    if cluster.isMaster

      for cpu in require('os').cpus()
        cluster.fork()
        console.log "[#{new Date()}] spawning worker"

      cluster.on 'exit', (worker) ->
        console.log "Worker [#{worker.id}] died"
        cluster.fork()

      console.log "[#{new Date()}] initializing pubnub"
      pubnub = pubnub.init(
        publish_key: 'nope'
        subscribe_key: 'sub-c-50d56e1e-2fd9-11e3-a041-02ee2ddab7fe'
      )

      console.log "[#{new Date()}] initializing kue web ui"
      kue.app.listen(3001)

      #https://mtgox.com/api/2/stream/list_public?pretty
      # btc -> usd ticker
      ticker_counter = 0
      pubnub.subscribe(
        channel  : "d5f06780-30a8-4a48-a2f8-7ed181b4a13f",
        callback : (message) =>
          console.log "[#{new Date()}] Ticker [#{ticker_counter++}]"
          jobs.create('ticker', payload: message).save()
      )
    else

      jobs.process 'ticker', (job, done) =>
        console.log "[#{new Date()}] Worker [#{cluster.worker.id}] | Processed Job Id: #{job.id}"
        pgConnection.writeTicker(job.data.payload)

        # push to rails via ws
        done()

#btc -> usd depth
#depth_counter = 0
#pubnub.subscribe(
  #channel  : "24e67e0d-1cad-4cc0-9e7a-f8523ef460fe",
  #callback : (message) ->
    ##console.log( " > ", message )
    #console.log "depth: ", depth_counter++
#)
#
new App()
