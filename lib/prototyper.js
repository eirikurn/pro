
/**
 * Module dependencies.
 */

var express = require('express');

/**
 * Add support for stylus in compiler
 */
express.compiler.compilers.stylus = {
  match: /\.css$/,
  ext: '.styl',
  compile: function(str, fn) {
    var stylus = cache.stylus || (cache.stylus = require('stylus'));
    try {
      fn(null, stylus.render(str));
    } catch (err) {
      fn(err);
    }
  }
};

/**
 * The prototype server
 */
function serve(options) {
  var app = express.createServer();
  app.use(express.static(options.dir));
  app.use(express.directory(options.dir, {icons: true}));
  app.use(express.compiler({ src: options.dir, enable: ['sass', 'less', 'stylus', 'coffeescript']}));

  app.listen(options.port, options.host);
  console.log("Prototyper listening on port %d", app.address().port);
}

exports.serve = serve;
