(function() {
  var FileRegistry, compilers, exports, fs, pathUtils, utils;

  fs = require('fs');

  pathUtils = require('path');

  utils = require('./utils');

  compilers = require('./compilers');

  FileRegistry = (function() {

    function FileRegistry(source, target) {
      this.source = source;
      this.target = target;
      this.files = [];
      this.filesBySource = {};
      this.filesByTarget = {};
    }

    FileRegistry.prototype.addFile = function(path, stats) {
      var compiler, file;
      var _this = this;
      compiler = this.getCompiler(path);
      file = new compiler.fileStrategy(path, stats, compiler, this);
      this.files.push(file);
      this.filesBySource[file.cleanPath] = file;
      if (!file.private) this.filesByTarget[file.targetPath] = file;
      utils.log("debug", "Found " + file.constructor.name + " at " + path);
      file.on('change', function() {
        return file.build(function(err) {
          if (err) return utils.logError(err);
        });
      });
      return file;
    };

    FileRegistry.prototype.scan = function(cb) {
      var addFile;
      var _this = this;
      addFile = function(path, stats, cb) {
        _this.addFile(path, stats);
        return cb();
      };
      return utils.iterateFolder(this.source, exports.ignore, addFile, function() {
        return _this.findDependencies(function() {
          return _this.buildOutdated(cb);
        });
      });
    };

    FileRegistry.prototype.findDependencies = function(cb) {
      var findDependencies, registry;
      registry = this;
      findDependencies = function(file, next) {
        return file.findDependencies(registry, next);
      };
      return utils.forEach(this.files, findDependencies, cb);
    };

    FileRegistry.prototype.lookupFile = function(path, cb) {
      var cleanPath;
      var _this = this;
      cleanPath = utils.cleanPath(path);
      if (this.filesBySource[cleanPath]) {
        return cb(null, this.filesBySource[cleanPath]);
      }
      return fs.stat(pathUtils.join(this.source, path), function(err, stats) {
        var file;
        if (err) return cb(err);
        if (stats.isDirectory()) return cb();
        file = _this.addFile(path, stats);
        return file.findDependencies(_this, function(err) {
          if (err) return cb(err);
          return file.build(cb);
        });
      });
    };

    FileRegistry.prototype.lookupTarget = function(path, cb) {
      var compiler, extension, potentialSources, sourceExt;
      potentialSources = [path];
      extension = utils.extname(path);
      for (sourceExt in compilers) {
        compiler = compilers[sourceExt];
        if (compiler.compilesTo === extension) {
          potentialSources.push(utils.newext(path, sourceExt));
        }
      }
      return utils.first(potentialSources, this.lookupFile.bind(this), cb);
    };

    FileRegistry.prototype.buildOutdated = function(cb) {
      var action;
      action = function(file, next) {
        if (file.private) return next();
        return file.isOutdated(function(err, outdated) {
          if (err || !outdated) return next(err);
          return file.build(next);
        });
      };
      return utils.forEach(this.files, action.logErrors(), cb);
    };

    FileRegistry.prototype.getCompiler = function(path) {
      var compiler, ext;
      ext = utils.extname(path);
      compiler = compilers[ext] || compilers["default"];
      return compiler;
    };

    return FileRegistry;

  })();

  exports = module.exports = FileRegistry;

  exports.ignore = ['node_modules', '_build'];

}).call(this);
