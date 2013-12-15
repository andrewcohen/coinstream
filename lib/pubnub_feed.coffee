pubnub = require('pubnub')
log    = require('./log')

# https://mtgox.com/api/2/stream/list_public?pretty
class PubNubFeed
  constructor: (options = {}) ->
    @options = options
    @ticker_counter = 0
    @initializePubNub()

  initializePubNub: ->
    @pubnub = pubnub.init(
      publish_key: 'nope'
      subscribe_key: 'sub-c-50d56e1e-2fd9-11e3-a041-02ee2ddab7fe'
    )
    log.info "Initialized PubNubFeed"

  ticker: (callback) ->
    @pubnub.subscribe(
      channel  : "d5f06780-30a8-4a48-a2f8-7ed181b4a13f",
      callback : (message) =>
        log.info "Ticker [#{@ticker_counter++}]"
        callback(message)
    )

#btc -> usd depth
#depth_counter = 0
#pubnub.subscribe(
  #channel  : "24e67e0d-1cad-4cc0-9e7a-f8523ef460fe",
  #callback : (message) ->
    ##console.log( " > ", message )
    #console.log "depth: ", depth_counter++
#)
#

module.exports = PubNubFeed
