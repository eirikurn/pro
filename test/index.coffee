
class exports.fs
  constructor: (@files) ->
    for k, v of @files
      if "string" == typeof v
        @files[k] = {content: v, time: +Date()}

  info: (path, cb) ->
    if path of @files
      return cb null, @_infoSync(path)
    cb @_enoent()

  readFile: (path, cb) ->
    if path of @files
      return cb null, @files[path].content
    cb @_enoent()

  writeFile: (path, str, cb) ->
    file = @files[path] or= {}
    file.content = str
    file.time = +Date()
    cb()

  watchFile: (path, cb) ->
    @files[path].watcher = cb

  unwatchFile: (path, cb) ->
    delete @files[path].watcher

  traverse: (path, ignore, iter, cb) ->
    results = []
    utils.forEach Object.keys(@files), (k, next) ->
      base = pathUtils.basename k
      return next() if base[0] == "." and base in ignore

      iter k, @_infoSync(k), (err, result) ->
        results.push result or k
        next()
    , ->
      cb(null, results)

  _touch: (path) ->
    file = @files[path]
    file.time = +Date()
    file.watcher? @_infoSync(path)

  _infoSync: (path) ->
    return time: @files[path].time

  _enoent: ->
    err = new Error("ENOENT")
    error.code = "ENOENT"
    return error
