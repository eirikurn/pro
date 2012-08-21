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
    if fsLevel++ == 0
      accessed[path] = (accessed[path] or 0) + 1
    try
      result = old(path, args...)
    finally
      fsLevel--

for h in hooked
  patchFunction(h)

accessed = {}
fsLevel = 0

exports.clear = ->
  accessed = {}

exports.getAccessed = -> Object.keys accessed
