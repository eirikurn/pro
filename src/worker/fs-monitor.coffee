fs          = require 'fs'
{Minimatch} = require 'minimatch'

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

filters = exports.defaultFilters = [
  # Do not track required code
  new Minimatch("!**/node_modules/**")

  # Do not match hidden files
  new Minimatch("**", {dot: false})
]

patchFunction = (name, ignore = false) ->
  old = fs[name]
  fs[name] = (path, args...) ->
    if fsLevel++ == 0 and not ignore
      # Check if the path matches the filter
      filtered = false
      for f in filters
        filtered = true unless f.match(path)
      unless filtered
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
  filters = exports.defaultFilters.concat (f and [new Minimatch(f)] or [])

exports.getAccessed = -> Object.keys accessed
