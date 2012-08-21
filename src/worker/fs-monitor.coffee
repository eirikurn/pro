fs        = require 'fs'
minimatch = require 'minimatch'

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
      if not filter or minimatch(path, filter)
        accessed[path] = (accessed[path] or 0) + 1
    try
      result = old(path, args...)
    finally
      fsLevel--

for h in hooked
  patchFunction(h)

accessed = {}
fsLevel = 0
filter = null

exports.clear = ->
  accessed = {}

exports.setFilter = (f) ->
  filter = f

exports.getAccessed = -> Object.keys accessed
