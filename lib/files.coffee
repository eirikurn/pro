##
# Module dependencies
##
fs = require 'fs'
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

  lookup: (path) ->
    @files[path]

  scan: (cb) ->
    files = @files
    processFile = (path, stats, cb) ->
      ctr = getFileConstructor path
      file = new ctr(path, stats)
      files[path] = file
      utils.log "debug", "Found #{file.constructor.name} at #{path}"
      cb()

    utils.iterateFolder @source, proignore, processFile, =>
      @findDependencies =>
        @buildOutdated cb

  findDependencies: (cb) ->
    self = this
    paths = Object.keys(@files)
    processFile = (i) ->
      path = paths[i]
      return cb() unless path

      self.files[path].findDependencies self, (err) ->
        processFile(i+1)

    processFile(0)

  buildOutdated: (cb) ->
    self = this
    paths = Object.keys(@files)

    processFile = (i) ->
      path = paths[i]
      return cb() unless path

      file = self.files[path]
      targetPath = pathUtils.join self.target, path

      if file.compiler.compilesTo
        targetPath = targetPath.replace(extension, "." + file.compiler.compilesTo)

      build = ->
        file.build targetPath, (err) ->
          utils.log "error", err if err
          processFile(i+1)
      skip = ->
        processFile(i+1)

      fs.stat targetPath, (err, stats) ->
        if err
          if err.code == "ENOENT"
            utils.log "debug", "Building non-existant #{path}"
            build()
          else
            utils.log "warn", "Error accessing file #{targetPath}"
            skip()
        else if file.isNewerThan(stats.mtime)
          utils.log "debug", "Building outdated #{path}"
          build()
        else
          utils.log "debug", "Not building up-to-date #{path}"
          skip()

    processFile(0)

getFileConstructor = (args...) ->
  path = args[0]
  ext = pathUtils.extname(path)[1..]
  compiler = Compilers[ext]
  return compiler?.fileStrategy or File

class File
  constructor: (@path, @stats) ->
    @dependsOn = []
    @dependedBy = []
    @extension = pathUtils.extname(@path)[1..]
    @compiler = Compilers[@extension] or Compilers.default

  findDependencies: (registry, cb) ->
    cb()

  build: (target, cb) ->
    utils.log "info", "Building #{@path}"
    self = this

    fs.readFile self.path, "utf8", (err, str) ->
      return cb(err) if err
      self.compile str, (err, str) ->
        return cb(err) if err
        utils.safeWriteFile target, str, "utf8", (err) ->
          cb(err)

  compile: (str, cb) ->
    try
      @compiler.compile str, {filename: @path}, cb
    catch err
      cb err

  isNewerThan: (time) ->
    return true if @stats.mtime > time
    for f in @dependsOn
      return true if f.isNewerThan time
    return false

class TemplateFile extends File
  findDependencies: (registry, cb) ->
    @dependsOn = []
    hasLayout = (dirname) =>
      dirname = '' if dirname == '.'

      layoutPath = pathUtils.join(dirname, "layout.#{@extension}")
      layoutFile = registry.files[layoutPath]
      if layoutFile
        @dependsOn.push layoutFile
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

class LessFile extends File
  compile: (str, cb) ->
    try
      @compiler.compile str, {filename: @path}, (err, str) ->
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
      str = @jade.compile(str, options)()
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
