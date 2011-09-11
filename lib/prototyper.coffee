##
# Module dependencies.
##
pathUtils    = require('path')

utils        = require('./utils')
FileRegistry = require('./fileregistry')
Server       = require('./server')

exports.serve = (options) ->
  utils.setLogLevel(options.logLevel)

  registry = new FileRegistry(options.dir, options.output)
  registry.scan ->
    utils.log("info", "Finished scan")

  server = new Server(options, registry)

