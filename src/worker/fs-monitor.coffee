fs = require('fs')

hooked = [
  "readFile",
  "readFileSync",
  "open",
  "openSync",
  "stat",
  "statSync",
  "exists",
  "existsSync",
  "createReadStream"
]

patchFunction = (name) ->
  old = fs[name]
  fs[name] = (path, args...) ->
    accessed.append(path)
    return old(path, args...)

for h in hooked
  patchFunction(h)


accessed = []

exports.clear = ->
  accessed.length = 0

exports.getAccessed = -> accessed