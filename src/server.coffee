##
# Module dependencies.
##
express      = require 'express'
pathUtils    = require 'path'
url          = require 'url'
utils        = require './utils'

class Server
  constructor: (@registry) ->
    app = express.createServer()
    app.use(express.logger('dev'))
    app.use(express.favicon())
    # app.use(@checkRegistry)
    app.use(express.static(process.env.PRO_TARGET))
    app.use(express.directory(process.env.PRO_TARGET, {icons: true}))

    server = url.parse(process.env.PRO_BASE_URL)

    if server.protocol == 'http:'
      app.listen(server.port or 80, server.hostname)
    else
      utils.log("error", "Pro server can not be run with SSL. Yet.")
      process.exit()

    accessibleAt = server.protocol + "//localhost" + (server.port and ":#{server.port}") + "/"
    utils.log("info", "Prototyper server running on #{accessibleAt}")

  checkRegistry: (req, res, next) =>
    path = url.parse(req.url).pathname[1..]
    if path[path.length-1] == '/'
      path += "index.html"
    path = pathUtils.normalize(path)

    @registry.lookupTarget path, (err, file) ->
      next(err)

module.exports = Server
