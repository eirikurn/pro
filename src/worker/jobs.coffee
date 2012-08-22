fs        = require 'fs'

# Is imported first to override node's fs methods before compilers can cache them.
monitor   = require './fs-monitor'
compilers = require '../compilers'


exports.compile = (job, cb) ->
  compiler = compilers.forFile(job.source)
  encoding = if 'encoding' of compiler then compiler.encoding else 'utf8'

  file = fs.readFileSync(job.source, encoding)

  monitor.clear()

  compiler.compile file, job.options, (err, result) ->
    fs.writeFileSync(job.target, result, encoding) unless err

    cb err, { dependencies: monitor.getAccessed() }