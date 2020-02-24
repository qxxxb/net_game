import
  times,
  os,
  clean_game/util / [logging, ticks],
  clean_game/net/server as net_server,
  clean_game/server/global

type Server* = ref object
  netServer: net_server.Server

proc newServer(): Server =
  new result
  global.tick = 0
  result.netServer = net_server.newServer()
  result.netServer.open()

proc destroy(server: Server) =
  server.netServer.close()

proc update(server: Server) =
  discard

proc main() =
  initLogging("server")

  var server = newServer()
  defer: server.destroy()

  while true:
    let tickStart = times.getTime()

    let runNet = net_server.shouldRunNet()
    if runNet:
      server.netServer.recv()

    server.update()

    if runNet:
      server.netServer.send()

    # Sleep until next tick needed
    let elapsed = times.getTime() - tickStart
    let sleepDuration = ticks.duration - elapsed
    if (sleepDuration > DurationZero):
      sleep(sleepDuration.inMilliseconds().int())
    else:
      warn "Tick ran for longer than `tickDuration`"
      warn "`tickDuration - elapsed`: ", sleepDuration

    global.tick.inc()

main()
