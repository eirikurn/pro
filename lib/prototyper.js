
/**
 * Module dependencies.
 */

var express = require('express')
  , compiler = require('./compiler')
  ;

/**
 * The prototype server
 */
function serve(options) {
  var app = express.createServer();
  app.use(express.logger('dev'));
  app.use(compiler.middleware(options.dir));
  app.use(express.static(options.dir));
  app.use(express.directory(options.dir, {icons: true}));

  app.listen(options.port, options.host);
  console.log("Prototyper listening on port %d", app.address().port);
}

exports.serve = serve;
