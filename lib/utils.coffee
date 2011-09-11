##
# Module dependencies
##
fs = require 'fs'
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
  console.log "[#{logLevels[3].toUpperCase()}]", msg or error.toString()
  if msg then console.log error.toString()


logLevels = ['debug', 'info', 'warn', 'error']
currentLevel = 1
exports.setLogLevel = (level) ->
  currentLevel = logLevels.indexOf level
  throw new Error("No log level named #{level}") if currentLevel == -1

# Regexp to find and replace file extensions
extension = /\.(\w+)$/

# Returns the extension of the specified file, or the empty string
exports.extname = (path) -> extension.exec(path)?[1] or ""

# Switches extensions of the path
exports.newext = (path, ext) -> path.replace(extension, "." + ext)


# Regexp to detect private files
private = /(^|[/\\])_/g

# Returns true if the file path has a part that starts with an underscore (_)
exports.isPrivate = (path) ->
  private.test path

# Trims underscore from the start of all parts in the specified path.
exports.cleanPath = (path) ->
  path.replace private, "$1"

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

