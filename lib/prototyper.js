
/**
 * Module dependencies.
 */

var express = require('express')
  , pathUtils = require('path')
  , utils = require('./utils')
  , FileRegistry = require('./files').FileRegistry
  ;

/**
 * Global state
 */
var registry = null;

/**
 * The prototype server
 */
function serve(options) {
  utils.setLogLevel(options.logLevel);

  var app = express.createServer();
  app.use(express.logger('dev'));
  app.use(express.favicon());
  app.use(express.static(options.output));
  app.use(express.directory(options.output, {icons: true}));

  app.listen(options.port, options.host);
  utils.log("info", "Prototyper listening on port " + app.address().port);

  registry = new FileRegistry(options.dir, options.output);
  registry.scan(function() {
    utils.log("info", "Finished scan");
  });
}

exports.serve = serve;
