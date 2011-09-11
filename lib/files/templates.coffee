pathUtils = require 'path'
utils = require '../utils'
{File} = require './index'

# Handles compilation of jade files.
# Supports layout compilation and dependency tracking.
class TemplateFile extends File

  findDependencies: (registry, cb) ->
    @resetDependencies()

    tries = []; dirname = @cleanPath
    while dirname != ''
      dirname = pathUtils.dirname dirname
      dirname = '' if dirname == '.'
      layoutPath = pathUtils.join(dirname, "layout.#{@extension}")
      tries.push layoutPath unless @cleanPath == layoutPath

    lookupFile = registry.lookupFile.bind(registry)
    utils.first tries, lookupFile, (err, layoutFile) =>
      return cb(err) if err or not layoutFile

      @addDependency layoutFile
      utils.log "debug", "Found layout for #{@path}"
      cb()

  read: (cb) ->
    if @lastRead > @stats.mtime
      return cb(null, @lastFile)

    super (err, str) =>
      return cb(err) if err
      @lastRead = Date()
      @lastFile = str
      cb null, @lastFile

  compile: (str, options, cb) ->
    options.page or= {}
    super str, options, (err, str) =>
      return cb(err, str) if err or @dependsOn.length == 0

      options.body = str
      @dependsOn[0].read (err, str) =>
        return cb(err) if err
        @dependsOn[0].compile str, options, cb

exports.TemplateFile = TemplateFile
