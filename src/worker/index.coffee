# Needs to be imported first to override node's fs methods before other modules cache them.
monitor = require './fs-monitor'
compilers = require '../compilers'

process.on 'message', (m) ->
  if m.type != 'compile'
    return

  file = fs.readSync(m.source)
  compiler = compilers[path.extname(m.source)]

  monitor.clear()
  compiler.compile file, {}, (err, result) ->
    fs.writeSync(m.target, result) unless err
    msg = { result: err and 'error' or 'success', deps: monitor.getAccessed() }
    msg.error = err if err
    process.send(msg)


