##
# Module dependencies
##
fs = require 'fs'
pathUtils = require 'path'
{EventEmitter} = require 'events'

utils = require '../utils'

class File extends EventEmitter
    
  constructor: (@path, @stats, @compiler, registry) ->
    @dependsOn = []
    @extension = utils.extname @path
    @private = utils.isPrivate @path
    @cleanPath = utils.cleanPath @path
    @sourcePath = pathUtils.join registry.source, @path
    @encoding = if 'encoding' of @compiler then @compiler.encoding else 'utf8'
    unless @private
      @targetPath = pathUtils.join registry.target, @path
      if @compiler.compilesTo
        @targetPath = utils.newext @targetPath, @compiler.compilesTo

    fs.watch @sourcePath, (event) =>
      fs.stat @sourcePath, (e, newStats) =>
        @onChange(newStats) unless e

  findDependencies: (registry, cb) ->
    cb()

  onDependencyChange: =>
    @emit 'change'

  resetDependencies: ->
    for f in @dependsOn
      f.removeListener 'change', @onDependencyChange
    @dependsOn.length = 0

  addDependency: (file) ->
    @dependsOn.push file
    file.on 'change', @onDependencyChange

  build: (cb) ->
    if @private
      utils.log "debug", "Ignoring build of private file #{@path}"
      return cb()
    utils.log "info", "Building #{@path}"

    @read (err, str) =>
      return cb(err) if err
      @compile str, {}, (err, str) =>
        return cb(err) if err
        utils.safeWriteFile @targetPath, str, @encoding, (err) ->
          cb(err)

  compile: (str, options, cb) ->
    try
      options.filename = @path
      @compiler.compile str, options, cb
    catch err
      cb err

  read: (cb) ->
    fs.readFile @sourcePath, @encoding, cb

  onChange: (newStats) ->
    if newStats.mtime > @stats.mtime
      @stats = newStats
      @emit 'change'

  isOutdated: (cb) ->
    cb(new Error("Private files can't be outdated")) if @private

    fs.stat @targetPath, (err, stats) =>
      if err
        if err.code == "ENOENT"
          cb(null, true)
        else
          cb(err)
      else if @isNewerThan(stats.mtime)
        cb(null, true)
      else
        cb(null, false)

  isNewerThan: (time) ->
    return true if time < @stats.mtime
    for f in @dependsOn
      return true if f.isNewerThan time
    return false

exports.File = File

for module in ['./stylesheets', './templates']
  for name, type of require module
    exports[name] = type

