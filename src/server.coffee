##
# Module dependencies.
##
express      = require 'express'
pathUtils    = require 'path'
url          = require 'url'
utils        = require './utils'

class Server
  constructor: (options, @registry) ->
    app = express.createServer()
    app.use(express.logger('dev'))
    app.use(express.favicon())
    app.use(@checkRegistry)
    app.use(express.static(options.output))
    app.use(express.directory(options.output, {icons: true}))

    app.listen(options.port, options.host)
    utils.log("info", "Prototyper listening on port " + options.port)

  checkRegistry: (req, res, next) =>
    path = url.parse(req.url).pathname[1..]
    if path[path.length-1] == '/'
      path += "index.html"
    path = pathUtils.normalize(path)

    @registry.lookupTarget path, (err, file) ->
      next(err)

module.exports = Server
