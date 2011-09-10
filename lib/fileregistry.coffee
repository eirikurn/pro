# Dependencies
pathUtils = require 'path'
utils = require './utils'
files = require './files'

##
# File registry
##
class FileRegistry

  constructor: (@source, @target) ->
    @files = []

  addFile: (path, stats) ->
    compiler = @getCompiler path
    file = new compiler.fileStrategy(path, stats, compiler, this)
    @files[file.cleanPath] = file

    utils.log "debug", "Found #{file.constructor.name} at #{path}"

    file.on 'change', =>
      file.build (err) ->
        utils.logError(err, "Error building file #{file.path}") if err

    return file

  scan: (cb) ->
    processFile = (path, stats, cb) =>
      @addFile(path, stats)
      cb()

    utils.iterateFolder @source, exports.ignore, processFile, =>
      @findDependencies =>
        @buildOutdated cb

  findDependencies: (cb) ->
    paths = Object.keys(@files)
    processFile = (i) =>
      path = paths[i]
      return cb() unless path

      @files[path].findDependencies this, (err) ->
        processFile(i+1)

    processFile(0)

  lookupFile: (path, cb) ->
    if @files[path]
      return cb(null, @files[path])
    else
      fs.stat pathUtils.join(@source, path), (err, stats) ->
        return cb(err) if err
        cb(null, addFile(path, stats))

  buildOutdated: (cb) ->
    filesToCheck = (file for path, file of @files when not file.private)

    processFile = (i) =>
      file = filesToCheck[i]
      return cb() unless file

      next = (err) ->
        utils.logError(err, "Error processing file #{file.path}") if err
        processFile(i+1)

      file.isOutdated (err, outdated) =>
        if err or not outdated
          return next(err)
        file.build next

    processFile(0)

  getCompiler: (path) ->
    ext = pathUtils.extname(path)[1..]
    compiler = exports.Compilers[ext] or exports.Compilers.default
    return compiler

exports = module.exports = FileRegistry

##
# Which files to ignore
##
exports.ignore = ['node_modules', '_build']

##
# Compiled file types.
#
# * key:          the file extension of the source file
# * compilesTo:   the target file extension
# * fileStrategy: a class that handles dependency tracking and complex compilations
# * compile:      a function that receives source file contents and should call
#                 its callback with the target file contents
##
exports.Compilers =
  jade:
    compilesTo: 'html'
    fileStrategy: files.TemplateFile
    compile: (str, options, cb) ->
      @jade or= require "jade"
      str = @jade.compile(str, options)(options)
      cb(null, str)

  styl:
    compilesTo: 'css'
    fileStrategy: files.StylesheetFile
    compile: (str, options, cb) ->
      @stylus or= require "stylus"
      @stylus.render(str, options, cb)

  less:
    compilesTo: 'css'
    fileStrategy: files.LessFile
    compile: (str, options, cb) ->
      @less or= require "less"
      @less.render str, options, cb

  coffee:
    compilesTo: 'js'
    fileStrategy: files.File
    compile: (str, options, cb) ->
      @coffee or= require "coffee-script"
      cb null, @coffee.compile(str, options)

  default:
    fileStrategy: files.File
    compile: (str, options, cb) -> cb(null, str)
