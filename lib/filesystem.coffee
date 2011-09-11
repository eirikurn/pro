pathUtils = require 'path'
fs = require 'fs'
utils = require './utils'

watchers = {}

module.exports =
  info: fs.stat

  readFile: (path, cb) ->
    fs.readFile(path, "utf8", cb)

  writeFile: (path, str, cb) ->
    safeWriteFile(path, str, "utf8", cb)

  watchFile: (path, cb) ->
    watcher = (newStats, oldStats) ->
      if newStats.mtime > oldStats.mtime
        cb(newStats)

    watchers[path] or= []
    watchers[path].push [cb, watcher]
    fs.watchFile path, watcher

  unwatchFile: (path, cb) ->
    for w in watchers[path]
      if cb == w[0]
        fs.unwatchFile path, w[1]

  traverse: (path, ignore, iter, cb) ->
    iterateFolder path, ignore, iter, cb

##
# File system utils
##

# Creates all parent directories needed for the specified path
createFolders = (path, cb) ->
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

# Writes the file, creating parent folders if needed
safeWriteFile = (path, str, mode, cb) ->
  fs.writeFile path, str, mode, (err) ->
    if not err or err.code != "ENOENT"
      cb(err)
    else
      utils.createFolders pathUtils.dirname(path), (err) ->
        return cb(err) if err

        # Only try once more!
        fs.writeFile path, str, mode, cb

# Iterates a folder
iterateFolder = (folder, ignoreList, cb, after, prefix = "") ->
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
