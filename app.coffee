cluster = require('cluster')
pubnub  = require('pubnub')
kue     = require('kue')
pg      = require('pg')
jobs    = kue.createQueue()


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
    saveToDb(job.data.payload)
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


conn_string = "postgres://localhost/coinflux_development"

client = new pg.Client(conn_string)
client.connect (err) ->
  if err
    console.error('could not connect to postgres.  reason:', err)

`

function saveToDb(data) {
  var queryString = 'insert into ticker_prices ';
  queryString += ' ("date", "buy", "sell", "high", "low", "last_local", "last_orig", "vwap", "avg") ';
  queryString += 'values ('
  queryString += 'NOW()' + ',';
  queryString += data.ticker.buy.value_int + ',';
  queryString += data.ticker.sell.value_int + ',';
  queryString += data.ticker.high.value_int + ',';
  queryString += data.ticker.low.value_int + ',';
  queryString += data.ticker.last_local.value_int + ',';
  queryString += data.ticker.last_orig.value_int + ',';
  queryString += data.ticker.vwap.value_int + ',';
  queryString += data.ticker.avg.value_int;
  queryString += ');';
  //console.log(queryString);

  client.query(queryString, function(err, result) {
    if (err) {
      return console.error('query err', err);
    }
    client.end()
  });
}
`
