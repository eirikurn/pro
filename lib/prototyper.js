
/**
 * Module dependencies.
 */

var express = require('express');


function serve(host, port) {
  var app = express.createServer();

  app.listen(port, host);
  console.log("Prototyper listening on port %d", app.address().port);
}

exports.serve = serve;
