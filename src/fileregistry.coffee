# Dependencies
fs        = require 'fs'
pathUtils = require 'path'

compilers = require './compilers'
utils     = require './utils'
worker    = require './worker'

##
# File registry
##
class FileRegistry

  constructor: ->
    @dependencies = {}
    @workers = new worker.WorkerQueue()
    @source = process.env.PRO_SOURCE
    @target = process.env.PRO_TARGET
    @shouldWatch = !process.env.PRO_JUST_BUILD


  addFile: (path, stats, cb) ->
    # Track it
    @sources[path] = stats

    # Full source file path
    sourcePath = pathUtils.join(@source, path)

    # Track it
    if @shouldWatch
      utils.watchit sourcePath, (e) ->
        return unless e == 'change'
        fs.stat sourcePath, (e, stats) ->
          @sources[path] = stats

    # Nothing more if it is private
    if utils.isPrivate(path)
      return cb()

    # Full target file path
    compiler = compilers.forFile(path)
    path = utils.newext(path, compiler.compilesTo) if compiler.compilesTo
    targetPath = pathUtils.join(@target, path)

    job =
      source: sourcePath
      target: targetPath
      options:
        filename: sourcePath

    utils.log "info", "Building #{path}"
    @workers.queueJob "compile", job, (e, result) =>
      if e
        utils.logError e
      else
        @dependencies[path] = result.dependencies
      cb(e)


  scan: (cb) ->
    utils.iterateFolder @source, exports.ignore, @addFile.bind(this), cb


exports = module.exports = FileRegistry

##
# Which files to ignore
##
exports.ignore = ['node_modules', '_build']

