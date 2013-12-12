var gox = require('goxstream');

var options = {
  currency: 'USD',
  ticker: true,
  //depth: true,
  //trade: true,
  //lag: true
};

var stream = gox.createStream(options);

stream.on('error', function(data) {
  console.log("ERROR: ", data)
});

var depthCt = 0, tickerCt = 0, tradeCt = 0;

stream.on('data', function(data) {
  if(data.length <= 1) return;
  try {
    data = JSON.parse(data);
    if(data.channel_name == "ticker.BTCUSD") {
      //console.log(data);
      console.log(new Date(), "data received")
      saveToDb(data);
      tickerCt++;
    }
    else {
      depthCt++;
    }
  }
  catch (e) {
    console.log("stream parse error: ", e)
  }

  console.log("ticker: ", tickerCt, " | depth: ", depthCt);
});

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
  queryString += ' ("date", buy", "sell", "high", "low", "last_local", "last_orig", "vwap", "avg") ';
  queryString += 'values ('
  queryString += 'NOW(),';
  queryString += data.ticker.buy.value_int + ',';
  queryString += data.ticker.sell.value_int + ',';
  queryString += data.ticker.low.value_int + ',';
  queryString += data.ticker.last_local.value_int + ',';
  queryString += data.ticker.last_orig.value_int + ',';
  queryString += data.ticker.vwap.value_int + ',';
  queryString += data.ticker.avg.value_int + '';
  queryString += ');';
  console.log(queryString);

  client.query(queryString, function(err, result) {
    if (err) {
      return console.error('query err', err);
    }
    client.end()
  });

}


