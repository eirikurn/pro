##
# Module dependencies
##
fs = require 'fs'
pathUtils = require 'path'
{EventEmitter} = require 'events'

utils = require '../utils'

# Regexp to find and replace file extensions
extension = /\.(\w+)$/

# Regexp to detect private files
private = /(^|[/\\])_/g

class File extends EventEmitter
  constructor: (@path, @stats, @compiler, registry) ->
    @dependsOn = []
    @extension = pathUtils.extname(@path)[1..]
    @private = private.test @path
    @cleanPath = @path.replace private, "$1"
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
    if @private
      utils.log "debug", "Ignoring build of private file #{@path}"
      return cb()
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

exports.File = File

for module in ['./stylesheets', './templates']
  for name, type of require module
    exports[name] = type

