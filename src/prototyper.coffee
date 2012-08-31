##
# Module dependencies.
##
pathUtils    = require('path')

utils        = require('./utils')
FileRegistry = require('./fileregistry')
Server       = require('./server')

# Package version
exports.version = "0.3.0"

# Main
exports.start = (options) ->
  registry = new FileRegistry()
  registry.scan ->
    utils.log("info", "Finished scan")

  server = new Server(registry)

