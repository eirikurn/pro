(function() {
  var File, TemplateFile, pathUtils, utils;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  pathUtils = require('path');

  utils = require('../utils');

  File = require('./index').File;

  TemplateFile = (function() {

    __extends(TemplateFile, File);

    function TemplateFile() {
      var c, k;
      TemplateFile.__super__.constructor.apply(this, arguments);
      this.layoutExtensions = (function() {
        var _ref, _results;
        _ref = require('../compilers');
        _results = [];
        for (k in _ref) {
          c = _ref[k];
          if (c.supportsBody) _results.push(k);
        }
        return _results;
      })();
    }

    TemplateFile.prototype.findDependencies = function(registry, cb) {
      var dirname, ext, layoutPath, lookupFile, tries, _i, _len, _ref;
      var _this = this;
      this.resetDependencies();
      tries = [];
      dirname = this.cleanPath;
      while (dirname !== '') {
        dirname = pathUtils.dirname(dirname);
        if (dirname === '.') dirname = '';
        _ref = this.layoutExtensions;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          ext = _ref[_i];
          layoutPath = pathUtils.join(dirname, "layout." + ext);
          if (this.cleanPath !== layoutPath) tries.push(layoutPath);
        }
      }
      lookupFile = registry.lookupFile.bind(registry);
      return utils.first(tries, lookupFile, function(err, layoutFile) {
        if (err || !layoutFile) return cb(err);
        _this.addDependency(layoutFile);
        utils.log("debug", "Found layout for " + _this.path);
        return cb();
      });
    };

    TemplateFile.prototype.read = function(cb) {
      var _this = this;
      if (this.lastRead > this.stats.mtime) return cb(null, this.lastFile);
      return TemplateFile.__super__.read.call(this, function(err, str) {
        if (err) return cb(err);
        _this.lastRead = Date();
        _this.lastFile = str;
        return cb(null, _this.lastFile);
      });
    };

    TemplateFile.prototype.compile = function(str, options, cb) {
      var _this = this;
      options.page || (options.page = {});
      return TemplateFile.__super__.compile.call(this, str, options, function(err, str) {
        if (err || _this.dependsOn.length === 0) return cb(err, str);
        options.body = str;
        return _this.dependsOn[0].read(function(err, str) {
          if (err) return cb(err);
          return _this.dependsOn[0].compile(str, options, cb);
        });
      });
    };

    return TemplateFile;

  })();

  exports.TemplateFile = TemplateFile;

}).call(this);
