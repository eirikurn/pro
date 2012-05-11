(function() {
  var createFolders, currentLevel, extension, first, forEach, fs, iterateFolder, logLevels, pathUtils, private, utils;
  var __slice = Array.prototype.slice, __hasProp = Object.prototype.hasOwnProperty, __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (__hasProp.call(this, i) && this[i] === item) return i; } return -1; };

  fs = require('fs');

  pathUtils = require('path');

  utils = exports;

  exports.log = function() {
    var level, levelNr, msg;
    level = arguments[0], msg = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    levelNr = logLevels.indexOf(level);
    if (levelNr < 0) {
      msg.unshift(level);
      levelNr = 1;
    }
    if (levelNr >= currentLevel) {
      return console.log.apply(console, ["[" + (logLevels[levelNr].toUpperCase()) + "]"].concat(__slice.call(msg)));
    }
  };

  exports.logError = function(error, msg) {
    console.log("[" + (logLevels[3].toUpperCase()) + "]", msg || error.toString());
    if (msg) return console.log(error.toString());
  };

  logLevels = ['debug', 'info', 'warn', 'error'];

  currentLevel = 1;

  exports.setLogLevel = function(level) {
    currentLevel = logLevels.indexOf(level);
    if (currentLevel === -1) throw new Error("No log level named " + level);
  };

  createFolders = exports.createFolders = function(path, cb) {
    var parent, _create;
    parent = pathUtils.dirname(path);
    _create = function() {
      return fs.mkdir(path, 0755, function(err) {
        if (err && err.code === "EEXIST") err = null;
        return cb(err);
      });
    };
    return pathUtils.exists(parent, function(exists) {
      if (exists) {
        return _create();
      } else {
        return createFolders(parent, function(err) {
          if (err) return cb(err);
          return _create();
        });
      }
    });
  };

  exports.safeWriteFile = function(path, str, mode, cb) {
    return fs.writeFile(path, str, mode, function(err) {
      if (!err || err.code !== "ENOENT") {
        return cb(err);
      } else {
        return utils.createFolders(pathUtils.dirname(path), function(err) {
          if (err) return cb(err);
          return fs.writeFile(path, str, mode, cb);
        });
      }
    });
  };

  extension = /\.(\w+)$/;

  exports.extname = function(path) {
    var _ref;
    return ((_ref = extension.exec(path)) != null ? _ref[1] : void 0) || "";
  };

  exports.newext = function(path, ext) {
    return path.replace(extension, "." + ext);
  };

  iterateFolder = exports.iterateFolder = function(folder, ignoreList, cb, after, prefix) {
    var results;
    if (prefix == null) prefix = "";
    fs = require('fs');
    results = [];
    return fs.readdir(folder, function(err, files) {
      var processFile;
      if (err) return after(err);
      processFile = function(i) {
        var filename, next, path, resultPath;
        filename = files[i];
        resultPath = pathUtils.join(prefix, filename);
        path = pathUtils.join(folder, filename);
        next = function(err, paths) {
          if (err) utils.log("debug", "Error iterating " + path + ": " + err);
          if (paths) results.push.apply(results, paths);
          return processFile(i + 1);
        };
        if (!filename) return after(null, results);
        if (filename[0] === "." || __indexOf.call(ignoreList, resultPath) >= 0) {
          return next(null, []);
        }
        return fs.stat(path, function(err, stats) {
          if (stats) {
            if (stats.isDirectory()) {
              return iterateFolder(path, ignoreList, cb, next, resultPath);
            } else {
              return cb(resultPath, stats, function(err, result) {
                return next(err, [result || resultPath]);
              });
            }
          } else {
            return next(err, []);
          }
        });
      };
      return processFile(0);
    });
  };

  private = /(^|[/\\])_/g;

  exports.isPrivate = function(path) {
    return private.test(path);
  };

  exports.cleanPath = function(path) {
    return path.replace(private, "$1");
  };

  forEach = exports.forEach = function(arr, iter, cb) {
    var length, next;
    length = arr.length;
    next = function(i) {
      if (!(i < length)) return cb();
      return iter(arr[i], function(err) {
        if (err) return cb(err);
        return next(i + 1);
      });
    };
    return next(0);
  };

  first = exports.first = function(arr, iter, cb) {
    var interceptor;
    interceptor = function(item, next) {
      return iter(item, function(err, result) {
        if (result) return cb(null, result);
        return next();
      });
    };
    return utils.forEach(arr, interceptor, cb);
  };

  Function.prototype.toAsync = function() {
    var self;
    self = this;
    return function() {
      var args, cb, result, _i;
      args = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), cb = arguments[_i++];
      try {
        result = self.apply(this, args);
        return cb(null, result);
      } catch (err) {
        return cb(err);
      }
    };
  };

  Function.prototype.logErrors = function() {
    var self;
    self = this;
    return function() {
      var args, cb, _i;
      args = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), cb = arguments[_i++];
      args.push(function(err, result) {
        if (err) utils.logError(err);
        return cb(null, result);
      });
      return self.apply(this, args);
    };
  };

}).call(this);
