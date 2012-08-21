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

ignored = [
  "writeFile",
  "writeFileSync"
]

patchFunction = (name, ignore = false) ->
  old = fs[name]
  fs[name] = (path, args...) ->
    if fsLevel++ == 0 and not ignore
      # Check if the path matches the filter
      if not filter or minimatch(path, filter)
        accessed[path] = (accessed[path] or 0) + 1
    try
      result = old(path, args...)
    finally
      fsLevel--

for h in hooked
  patchFunction(h)

for h in ignored
  patchFunction(h, true)

accessed = {}
fsLevel = 0
filter = null

exports.clear = ->
  accessed = {}

exports.setFilter = (f) ->
  filter = f

exports.getAccessed = -> Object.keys accessed
