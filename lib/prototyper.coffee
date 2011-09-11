##
# Module dependencies.
##
pathUtils    = require('path')

utils        = require('./utils')
FileRegistry = require('./fileregistry')
Server       = require('./server')

# Package version
exports.version = "0.2.0"

# Main
exports.start = (options) ->
  utils.setLogLevel(options.logLevel)

  registry = new FileRegistry(options.dir, options.output, require('./filesystem'))
  registry.scan ->
    utils.log("info", "Finished scan")

  server = new Server(options, registry)

