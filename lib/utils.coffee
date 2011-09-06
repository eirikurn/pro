##
# Module dependencies
##
fs = require 'fs'
pathUtils = require 'path'

##
# Logging
##
exports.log = (level, msg...) ->
  level = logLevels.indexOf level
  if level < 0
    msg.push level
    level = 1
  if level >= currentLevel
    console.log "[#{logLevels[level].toUpperCase()}]", msg...

exports.logError = (error, msg) ->
  console.log "[#{logLevels[3].toUpperCase()}]", msg or error.toString()
  if msg then console.log error.toString()


logLevels = ['debug', 'info', 'warn', 'error']
currentLevel = 1
exports.setLogLevel = (level) ->
  currentLevel = logLevels.indexOf level
  throw new Error("No log level named #{level}") if currentLevel == -1

exports.createFolders = (path, cb) ->
  parent = pathUtils.dirname path
  _create = -> fs.mkdir path, 0755, (err) ->
    err = null if err and err.code == "EEXIST"
    cb(err)

  pathUtils.exists parent, (exists) ->
    if exists
      _create()
    else
      createFolders parent, (err) ->
        return cb(err) if err
        _create()

exports.safeWriteFile = (path, str, mode, cb) ->
  fs.writeFile path, str, mode, (err) ->
    if not err or err.code != "ENOENT"
      cb(err)
    else
      exports.createFolders pathUtils.dirname(path), (err) ->
        return cb(err) if err

        # Only try once more!
        fs.writeFile path, str, mode, cb


iterateFolder = exports.iterateFolder = (folder, ignoreList, cb, after, prefix = "") ->
  fs = require('fs')
  results = []
  fs.readdir folder, (err, files) ->
    return after(err) if err

    processFile = (i) ->
      path = files[i]
      return after(null, results) unless path

      resultPath = pathUtils.join(prefix, path)
      path = pathUtils.join(folder, path)
      next = (err, paths) ->
        if err then utils.log "debug", "Error iterating #{path}: #{err}"
        results.push.apply(results, paths) if paths
        processFile(i+1)

      return next(null, []) if resultPath in ignoreList

      fs.stat path, (err, stats) ->
        if stats
          if stats.isDirectory()
            iterateFolder(path, ignoreList, cb, next, resultPath)
          else
            cb resultPath, stats, (err, result) ->
              next(err, [result or resultPath])
        else
          next(err, [])

    processFile 0

##
# Let's emulate stylus errors to make the less errors a bit more useful.
# Heavily dependent on less error quirks.
##
exports.makeLessErrorSexy = (err) ->
  if err and err.toString == Object::toString
    err.toString = ->
      error = []
      nrSize = (@line + 1).toString().length
      error.push (@type or @name) + ": " + @filename
      error[0] += ":" + @line if @line
      if @extract
        error.push "  " + pad(@line-1, nrSize) + "| " + @extract[0] if @extract[0]
        error.push "> " + pad(@line, nrSize)   + "| " + @extract[1] if @extract[1]
        error.push "  " + pad(@line+1, nrSize) + "| " + @extract[2] if @extract[2]

      error.push ""
      error.push @message
      error.push ""
      error.push @stack
      return error.join "\n"

  pad = (integer, num) ->
    str = integer.toString()
    return Array(num-str.length).join(' ') + str

