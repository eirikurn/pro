(function() {
  var EventEmitter, File, fs, module, name, pathUtils, type, utils, _i, _len, _ref, _ref2;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  fs = require('fs');

  pathUtils = require('path');

  EventEmitter = require('events').EventEmitter;

  utils = require('../utils');

  File = (function() {

    __extends(File, EventEmitter);

    function File(path, stats, compiler, registry) {
      var _this = this;
      this.path = path;
      this.stats = stats;
      this.compiler = compiler;
      this.onDependencyChange = __bind(this.onDependencyChange, this);
      this.dependsOn = [];
      this.extension = utils.extname(this.path);
      this.private = utils.isPrivate(this.path);
      this.cleanPath = utils.cleanPath(this.path);
      this.sourcePath = pathUtils.join(registry.source, this.path);
      this.encoding = 'encoding' in this.compiler ? this.compiler.encoding : 'utf8';
      if (!this.private) {
        this.targetPath = pathUtils.join(registry.target, this.path);
        if (this.compiler.compilesTo) {
          this.targetPath = utils.newext(this.targetPath, this.compiler.compilesTo);
        }
      }
      fs.watch(this.sourcePath, function(event) {
        return fs.stat(_this.sourcePath, function(e, newStats) {
          if (!e) return _this.onChange(newStats);
        });
      });
    }

    File.prototype.findDependencies = function(registry, cb) {
      return cb();
    };

    File.prototype.onDependencyChange = function() {
      return this.emit('change');
    };

    File.prototype.resetDependencies = function() {
      var f, _i, _len, _ref;
      _ref = this.dependsOn;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        f = _ref[_i];
        f.removeListener('change', this.onDependencyChange);
      }
      return this.dependsOn.length = 0;
    };

    File.prototype.addDependency = function(file) {
      this.dependsOn.push(file);
      return file.on('change', this.onDependencyChange);
    };

    File.prototype.build = function(cb) {
      var _this = this;
      if (this.private) {
        utils.log("debug", "Ignoring build of private file " + this.path);
        return cb();
      }
      utils.log("info", "Building " + this.path);
      return this.read(function(err, str) {
        if (err) return cb(err);
        return _this.compile(str, {}, function(err, str) {
          if (err) return cb(err);
          return utils.safeWriteFile(_this.targetPath, str, _this.encoding, function(err) {
            return cb(err);
          });
        });
      });
    };

    File.prototype.compile = function(str, options, cb) {
      try {
        options.filename = this.path;
        return this.compiler.compile(str, options, cb);
      } catch (err) {
        return cb(err);
      }
    };

    File.prototype.read = function(cb) {
      return fs.readFile(this.sourcePath, this.encoding, cb);
    };

    File.prototype.onChange = function(newStats) {
      if (newStats.mtime > this.stats.mtime) {
        this.stats = newStats;
        return this.emit('change');
      }
    };

    File.prototype.isOutdated = function(cb) {
      var _this = this;
      if (this.private) cb(new Error("Private files can't be outdated"));
      return fs.stat(this.targetPath, function(err, stats) {
        if (err) {
          if (err.code === "ENOENT") {
            return cb(null, true);
          } else {
            return cb(err);
          }
        } else if (_this.isNewerThan(stats.mtime)) {
          return cb(null, true);
        } else {
          return cb(null, false);
        }
      });
    };

    File.prototype.isNewerThan = function(time) {
      var f, _i, _len, _ref;
      if (time < this.stats.mtime) return true;
      _ref = this.dependsOn;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        f = _ref[_i];
        if (f.isNewerThan(time)) return true;
      }
      return false;
    };

    return File;

  })();

  exports.File = File;

  _ref = ['./stylesheets', './templates'];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    module = _ref[_i];
    _ref2 = require(module);
    for (name in _ref2) {
      type = _ref2[name];
      exports[name] = type;
    }
  }

}).call(this);
