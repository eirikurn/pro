(function() {
  var Server, express, pathUtils, url, utils;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  express = require('express');

  pathUtils = require('path');

  url = require('url');

  utils = require('./utils');

  Server = (function() {

    function Server(options, registry) {
      var app;
      this.registry = registry;
      this.checkRegistry = __bind(this.checkRegistry, this);
      app = express.createServer();
      app.use(express.logger('dev'));
      app.use(express.favicon());
      app.use(this.checkRegistry);
      app.use(express.static(options.output));
      app.use(express.directory(options.output, {
        icons: true
      }));
      app.listen(options.port, options.host);
      utils.log("info", "Prototyper listening on port " + options.port);
    }

    Server.prototype.checkRegistry = function(req, res, next) {
      var path;
      path = url.parse(req.url).pathname.slice(1);
      if (path[path.length - 1] === '/') path += "index.html";
      path = pathUtils.normalize(path);
      return this.registry.lookupTarget(path, function(err, file) {
        return next(err);
      });
    };

    return Server;

  })();

  module.exports = Server;

}).call(this);
