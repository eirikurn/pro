# Dependencies
fs        = require 'fs'
pathUtils = require 'path'
utils     = require './utils'
compilers = require './compilers'

##
# File registry
##
class FileRegistry

  constructor: (@source, @target) ->
    @files = []
    @filesBySource = {}
    @filesByTarget = {}

  addFile: (path, stats) ->
    compiler = @getCompiler path
    file = new compiler.fileStrategy(path, stats, compiler, this)

    @files.push(file)
    @filesBySource[file.cleanPath] = file
    @filesByTarget[file.targetPath] = file unless file.private

    utils.log "debug", "Found #{file.constructor.name} at #{path}"

    file.on 'change', =>
      file.build (err) ->
        utils.logError(err) if err

    return file

  scan: (cb) ->
    addFile = (path, stats, cb) =>
      @addFile(path, stats)
      cb()

    utils.iterateFolder @source, exports.ignore, addFile, =>
      @findDependencies =>
        @buildOutdated cb

  findDependencies: (cb) ->
    registry = this
    findDependencies = (file, next) ->
      file.findDependencies registry, next

    utils.forEach @files, findDependencies, cb

  lookupFile: (path, cb) ->
    cleanPath = utils.cleanPath path
    if @filesBySource[cleanPath]
      return cb(null, @filesBySource[cleanPath])

    # NodeJS still doesn't have a good cross-platform watchDirectory api.
    # So we check here if it has been added since the initial scan.
    # If it does exist, we'll need to initialize and build it.
    fs.stat pathUtils.join(@source, path), (err, stats) =>
      return cb(err) if err
      return cb() if stats.isDirectory()

      file = @addFile(path, stats)
      file.findDependencies this, (err) ->
        return cb(err) if err

        file.build cb

  lookupTarget: (path, cb) ->
    potentialSources = [path]
    extension = utils.extname(path)

    for sourceExt, compiler of compilers when compiler.compilesTo == extension
      potentialSources.push utils.newext(path, sourceExt)

    utils.first potentialSources, @lookupFile.bind(this), cb

  buildOutdated: (cb) ->
    action = (file, next) ->
      return next() if file.private

      file.isOutdated (err, outdated) ->
        if err or not outdated
          return next(err)
        file.build next

    utils.forEach @files, action.logErrors(), cb

  getCompiler: (path) ->
    ext = utils.extname(path)
    compiler = compilers[ext] or compilers.default
    return compiler

exports = module.exports = FileRegistry

##
# Which files to ignore
##
exports.ignore = ['node_modules', '_build']

