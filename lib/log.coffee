class Log
  @message: (msg) ->
    "[#{new Date()}] #{msg}"

  @errorMsg: (msg) ->
    "Error: " << msg

  @info: (msg) -> console.log(@message(msg))
  @warn: (msg) -> console.warn(@message(msg))
  @error: (msg) -> console.error(@errorMsg(msg))

module.exports = Log
