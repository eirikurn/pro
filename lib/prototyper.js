(function() {
  var FileRegistry, Server, pathUtils, utils;

  pathUtils = require('path');

  utils = require('./utils');

  FileRegistry = require('./fileregistry');

  Server = require('./server');

  exports.version = "0.3.0";

  exports.start = function(options) {
    var registry, server;
    utils.setLogLevel(options.logLevel);
    registry = new FileRegistry(options.dir, options.output);
    registry.scan(function() {
      return utils.log("info", "Finished scan");
    });
    return server = new Server(options, registry);
  };

}).call(this);
