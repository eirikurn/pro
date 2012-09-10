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

  constructor: ->
    @dependencies = {}
    @workers = new worker.WorkerQueue()
    @source = process.env.PRO_SOURCE
    @target = process.env.PRO_TARGET
    @sources = {}
    @targetDeps = {}
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


  initialize: ->
    for s, stat of @sources
      target = @findTarget(s)
      if target
        if target not of @targetDeps or @targetDeps[target][0] != path
          @targetDeps[target] = [path]

    for t, deps of @targetDeps
      do (t, deps) =>
        fs.stat pathUtils.join(@target, t), (e, tStat) =>
          tTime = tStat?.mtime


  findTarget: (path) ->
    return null if utils.isPrivate(path)
    compiler = compilers.forFile(source)
    path = utils.newext(path, compiler.compilesTo) if compiler.compilesTo
    return path


  scan: (cb) ->
    options =
      ignoreDotFiles: true
      filter: (f) -> true
    watch.watchTree @source, options, (f, curr, prev) =>
      unless curr
        @sources = f
        @initialize()
    # utils.iterateFolder @source, exports.ignore, @addFile.bind(this), cb


exports = module.exports = FileRegistry

##
# Which files to ignore
##
exports.ignore = ['node_modules', '_build']

