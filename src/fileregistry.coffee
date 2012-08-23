# Dependencies
fs        = require 'fs'
pathUtils = require 'path'
watch     = require 'watch'

compilers = require './compilers'
utils     = require './utils'
worker    = require './worker'

##
# File registry
##
class FileRegistry

  constructor: (@source, @target) ->
    @dependencies = {}
    @workers = new worker.WorkerQueue()


  addFile: (path, stats, cb) ->
    compiler = compilers.forFile(path)

    sourcePath = pathUtils.join(@source, path)
    path = utils.newext(path, compiler.compilesTo) if compiler.compilesTo
    targetPath = pathUtils.join(@target, path)

    job =
      source: sourcePath
      target: targetPath
      options:
        filename: sourcePath

    utils.log "info", "Building #{path}"
    @workers.queueJob "compile", job, (e, result) =>
      @dependencies[path] = result.dependencies unless e
      cb(e)


  scan: (cb) ->
    utils.iterateFolder @source, exports.ignore, @addFile.bind(this), cb


exports = module.exports = FileRegistry

##
# Which files to ignore
##
exports.ignore = ['node_modules', '_build']

