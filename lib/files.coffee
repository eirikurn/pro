##
# Module dependencies
##
fs = require 'fs'
{EventEmitter} = require 'events'
pathUtils = require 'path'
utils = require './utils'


##
# Which files to ignore
##
proignore = exports.proignore = ['.git', 'node_modules', '_build']

##
# Regexp to find and replace file extensions
##
extension = /\.(\w+)$/

##
# File registry
##
class exports.FileRegistry
  constructor: (@source, @target) ->
    @files = []

  addFile: (path, stats) ->
    ctr = getFileConstructor path
    file = new ctr(path, stats, this)
    @files[path] = file
    utils.log "debug", "Found #{file.constructor.name} at #{path}"
    file.on 'change', => @buildFile file, ->
    return file

  scan: (cb) ->
    processFile = (path, stats, cb) =>
      @addFile(path, stats)
      cb()

    utils.iterateFolder @source, proignore, processFile, =>
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

  buildFile: (file, cb) ->
    file.build (err) ->
      utils.logError(err, "Error building file #{file.path}") if err
      cb(err)

  buildOutdated: (cb) ->
    paths = Object.keys(@files)

    processFile = (i) =>
      file = @files[paths[i]]
      return cb() unless file

      next = (err) ->
        utils.logError(err, "Error processing file #{paths[i]}") if err
        processFile(i+1)

      file.isOutdated (err, outdated) =>
        return next(err) if err
        @buildFile(file, next) if outdated

    processFile(0)

getFileConstructor = (args...) ->
  path = args[0]
  ext = pathUtils.extname(path)[1..]
  compiler = Compilers[ext]
  return compiler?.fileStrategy or File

class File extends EventEmitter
  constructor: (@path, @stats, registry) ->
    @dependsOn = []
    @dependedBy = []
    @extension = pathUtils.extname(@path)[1..]
    @compiler = Compilers[@extension] or Compilers.default
    @targetPath = pathUtils.join registry.target, path
    if @compiler.compilesTo
      @targetPath = @targetPath.replace(extension, "." + @compiler.compilesTo)

    fs.watchFile @path, (newStats, oldStats) => @onChange(newStats)

  onChange: (newStats) ->
    if newStats.mtime > @stats.mtime
      @stats = newStats
      @emit 'change'

  onDependencyChange: =>
    @emit 'change'

  findDependencies: (registry, cb) ->
    cb()

  resetDependencies: ->
    for f in @dependsOn
      f.removeListener 'change', @onDependencyChange
    @dependsOn.length = 0

  addDependency: (file) ->
    @dependsOn.push file
    file.on 'change', @onDependencyChange

  build: (cb) ->
    utils.log "info", "Building #{@path}"

    @read (err, str) =>
      return cb(err) if err
      @compile str, {}, (err, str) =>
        return cb(err) if err
        utils.safeWriteFile @targetPath, str, "utf8", (err) ->
          cb(err)

  compile: (str, options, cb) ->
    try
      options.filename = @path
      @compiler.compile str, options, cb
    catch err
      cb err

  read: (cb) ->
    fs.readFile @path, "utf8", cb

  isNewerThan: (time) ->
    return true if time > @stats.mtime
    for f in @dependsOn
      return true if f.isNewerThan time
    return false

  isOutdated: (cb) ->
    fs.stat @targetPath, (err, stats) =>
      if err
        if err.code == "ENOENT"
          cb(null, true)
        else
          cb(err)
      else if @isNewerThan(stats.mtime)
        cb(null, false)
      else
        cb(null, true)

class TemplateFile extends File
  findDependencies: (registry, cb) ->
    @resetDependencies()
    hasLayout = (dirname) =>
      dirname = '' if dirname == '.'

      layoutPath = pathUtils.join(dirname, "layout.#{@extension}")
      layoutFile = registry.files[layoutPath]
      if layoutFile
        @addDependency layoutFile
        utils.log "debug", "Found layout for #{@path}"
        cb()
      else if dirname == ''
        cb()
      else
        hasLayout pathUtils.dirname dirname

    if pathUtils.basename(@path) == "layout.#{@extension}"
      cb()
    else
      hasLayout pathUtils.dirname @path

  read: (cb) ->
    if @lastRead > @stats.mtime
      return cb(null, @lastFile)

    super (err, str) =>
      return cb(err) if err
      @lastRead = Date()
      @lastFile = str
      cb null, @lastFile

  compile: (str, options, cb) ->
    options.layout or= {}
    super str, options, (err, str) =>
      return cb(err, str) if err or @dependsOn.length == 0

      options.body = str
      @dependsOn[0].read (err, str) =>
        return cb(err) if err
        @dependsOn[0].compile str, options, cb

class LessFile extends File
  compile: (str, options, cb) ->
    try
      options.filename = @path
      @compiler.compile str, options, (err, str) ->
        utils.makeLessErrorSexy err
        cb err, str
    catch err
      utils.makeLessErrorSexy err
      cb err

Compilers =
  jade:
    compilesTo: 'html'
    fileStrategy: TemplateFile
    compile: (str, options, cb) ->
      @jade or= require "jade"
      str = @jade.compile(str, options)(options)
      cb(null, str)

  styl:
    compilesTo: 'css'
    fileStrategy: File
    compile: (str, options, cb) ->
      @stylus or= require "stylus"
      @stylus.render(str, options, cb)

  less:
    compilesTo: 'css'
    fileStrategy: LessFile
    compile: (str, options, cb) ->
      @less or= require "less"
      @less.render str, options, cb

  coffee:
    compilesTo: 'js'
    fileStrategy: File
    compile: (str, options, cb) ->
      @coffee or= require "coffee-script"
      cb null, @coffee.compile(str, options)

  default:
    compile: (str, options, cb) -> cb(null, str)
