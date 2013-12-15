pg  = require('pg')
log = require('./log')

class PgConnection
  @query: ->
    args = arguments
    conn_string = "postgres://localhost/coinflux_development"
    pg.connect(conn_string, (err, client, done) ->
      if err
        log.error('| postgres | error fetching client from pool: ', err)
      else
        client.query.apply(client, args)
        done()
    )

  @performQuery: (queryString, cb) =>
    @qs = queryString
    @query(queryString, (err, result) =>
      if err
        log.info("|postgres| error running query: #{queryString} \n #{err}")
      else
        log.info '| postgres | successful write'
        cb()
    )

  @writeTicker: (data, cb) ->
    queryString = """
      insert into ticker_prices ("created_at", "updated_at", "buy",
      "sell", "high", "low", "last_local", "last_orig", "vwap", "avg") values
      (NOW(), NOW(), #{data.buy.value_int}, #{data.sell.value_int},
      #{data.high.value_int}, #{data.low.value_int}, #{data.last_local.value_int},
      #{data.last_orig.value_int}, #{data.vwap.value_int}, #{data.avg.value_int});
    """

    @performQuery(queryString, cb)

  @writeDepth: (data, cb) ->
    queryString = """
      insert into depth_tickers ("created_at", "updated_at", "type_num",
      "type_str", "volume", "price", "item", "currency", "total_volume") values
      (NOW(), NOW(), #{data.type}, '#{data.type_str}', #{data.volume_int},
      #{data.price_int}, '#{data.item}', '#{data.currency}', #{data.total_volume_int});
    """

    @performQuery(queryString, cb)


module.exports = PgConnection
