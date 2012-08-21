compilers = require '../compilers'
monitor   = require './fs-monitor'

exports.compile = (job, cb) ->

  file = fs.readSync(job.source)
  compiler = compilers[path.extname(job.source)]

  monitor.clear()

  compiler.compile file, {}, (err, result) ->
    fs.writeSync(job.target, result) unless err

    cb err, { dependencies: monitor.getAccessed() }