fs        = require 'fs'

compilers = require '../compilers'
monitor   = require './fs-monitor'


exports.compile = (job, cb) ->
  compiler = compilers.forFile(job.source)
  encoding = if 'encoding' of compiler then compiler.encoding else 'utf8'

  file = fs.readFileSync(job.source, encoding)

  monitor.clear()

  compiler.compile file, job.options, (err, result) ->
    fs.writeFileSync(job.target, result, encoding) unless err

    cb err, { dependencies: monitor.getAccessed() }