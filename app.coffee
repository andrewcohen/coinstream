#https://mtgox.com/api/2/stream/list_public?pretty
pubnub = require('pubnub')
pubnub = pubnub.init(
  publish_key: 'nope'
  subscribe_key: 'sub-c-50d56e1e-2fd9-11e3-a041-02ee2ddab7fe'
)

console.log 'initialized pubnub'

# btc -> usd ticker
ticker_counter = 0
pubnub.subscribe(
  channel  : "d5f06780-30a8-4a48-a2f8-7ed181b4a13f",
  callback : (message) ->
    #console.log( " > ", message )
    console.log "ticker: ", ticker_counter++
    saveToDb(message)
)


#btc -> usd depth
#depth_counter = 0
#pubnub.subscribe(
  #channel  : "24e67e0d-1cad-4cc0-9e7a-f8523ef460fe",
  #callback : (message) ->
    ##console.log( " > ", message )
    #console.log "depth: ", depth_counter++
#)

`
var pg = require('pg');

var constring = "postgres://localhost/coinflux_development";

var client = new pg.Client(constring);

client.connect(function(err) {
  if (err) {
    return console.error('could not connect to postgres', err);
  }
});
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
  console.log(queryString);

  client.query(queryString, function(err, result) {
    if (err) {
      return console.error('query err', err);
    }
    client.end()
  });

}
`
