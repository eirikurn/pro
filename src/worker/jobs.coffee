fs        = require 'fs'

# The monitor is imported first so it can override fs functions
# before compilers cache them.
monitor   = require './fs-monitor'
compilers = require '../compilers'

##
# Receives a job object that contains the following properties:
#
#   source: path to a source file, a compiler is determined by its extension.
#   target: path to where the source file should be compiled.
#   options: options which are passed to the compiler. optional.
#
# The cb gets an object like this:
#
#   dependencies: array of file paths which were accessed during compilation.
exports.compile = (job, cb) ->
  compiler = compilers.forFile(job.source)
  encoding = if 'encoding' of compiler then compiler.encoding else 'utf8'

  file = fs.readFileSync(job.source, encoding)

  monitor.clear()

  compiler.compile file, job.options, (err, result) ->
    fs.writeFileSync(job.target, result, encoding) unless err

    cb err, { dependencies: monitor.getAccessed() }