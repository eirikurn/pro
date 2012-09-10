##
# Module dependencies
##
fs        = require 'fs'
pathUtils = require 'path'

utils = exports

##
# Logging
##
exports.log = (level, msg...) ->
  levelNr = logLevels.indexOf level
  if levelNr < 0
    msg.unshift level
    levelNr = 1
  if levelNr >= currentLevel
    console.log "[#{logLevels[levelNr].toUpperCase()}]", msg...

exports.logError = (error, msg) ->
  exports.log('error', msg or error.toString())
  if msg then console.log error.toString()


logLevels = ['debug', 'info', 'warn', 'error', 'none']

# Default level is INFO. Disable logging when running unit tests
currentLevel = logLevels.indexOf(process.env.PRO_LOG_LEVEL || 'info')

createFolders = exports.createFolders = (path, cb) ->
  parent = pathUtils.dirname path
  _create = -> fs.mkdir path, 0o755, (err) ->
    err = null if err and err.code == "EEXIST"
    cb(err)

  fs.exists parent, (exists) ->
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
      utils.createFolders pathUtils.dirname(path), (err) ->
        return cb(err) if err

        # Only try once more!
        fs.writeFile path, str, mode, cb

# Regexp to find and replace file extensions
extension = /\.(\w+)$/

# Returns the extension of the specified file, or the empty string
exports.extname = (path) -> extension.exec(path)?[1] or ""

# Switches extensions of the path
exports.newext = (path, ext) -> path.replace(extension, "." + ext)

iterateFolder = exports.iterateFolder = (folder, ignoreList, cb, after, prefix = "") ->
  fs = require('fs')
  results = []
  fs.readdir folder, (err, files) ->
    return after(err) if err

    processFile = (i) ->
      filename = files[i]
      resultPath = pathUtils.join(prefix, filename)
      path = pathUtils.join(folder, filename)

      next = (err, paths) ->
        if err then utils.log "debug", "Error iterating #{path}: #{err}"
        results.push.apply(results, paths) if paths
        processFile(i+1)

      return after(null, results) unless filename
      return  next(null, [])      if filename[0] == "." or resultPath in ignoreList

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

# Regexp to detect private files
privateRegexp = /(^|[/\\])_/g

# Returns true if the file path has a part that starts with an underscore (_)
exports.isPrivate = (path) ->
  privateRegexp.test path

# Trims underscore from the start of all parts in the specified path.
exports.cleanPath = (path) ->
  path.replace privateRegexp, "$1"

forEach = exports.forEach = (arr, iter, cb) ->
  length = arr.length
  next = (i) ->
    return cb() unless i < length

    iter arr[i], (err) ->
      return cb(err) if err
      next(i+1)
  next(0)

first = exports.first = (arr, iter, cb) ->
  interceptor = (item, next) ->
    iter item, (err, result) ->
      return cb(null, result) if result
      next()

  utils.forEach arr, interceptor, cb

Function.prototype.toAsync = ->
  self = this
  return (args..., cb) ->
    try
      result = self.apply this, args
      cb(null, result)
    catch err
      cb(err)

Function.prototype.logErrors = ->
  self = this
  return (args..., cb) ->
    args.push (err, result) ->
      utils.logError(err) if err
      cb(null, result)

    self.apply this, args

