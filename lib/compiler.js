/*!
 * Prototyper - compiler
 * Copyright(c) 2011 Eirikur Nilsson
 * MIT Licensed
 * Built from the Connect - compiler by Sencha Inc. and TJ Holowaychuk.
 */

/**
 * Module dependencies.
 */
var fs = require('fs')
  , path = require('path')
  , parse = require('url').parse
  ;

/**
 * Compiler
 */
exports = module.exports = function() {
  var extension = /\.(\w+)$/;
  var sourceCache = {};

  function _compileFile(src, dest, compiler, options, callback) {
    options = options || {};

    fs.stat(src, function(err, srcStats) {
      if (err) return callback(err);
      fs.stat(dest, function(err, destStats) {
        if (err) {
          // If it doesn't exist, we create it.
          if (err.code === 'ENOENT') {
            _runCompiler();
          } else {
            callback(err);
          }
        } else {
          // If it exists and is older, we create it.
          if (srcStats.mtime > destStats.mtime || options.force) {
            _runCompiler();
          } else {
            callback();
          }
        }
      });
    });

    function _runCompiler() {
      fs.readFile(src, 'utf8', function(err, str) {
        if (err) return callback(err);
        options.filename = src;
        compiler(str, options, function(err, str) {
          if (err) return callback(err);
          fs.writeFile(dest, str, 'utf8', function(err) {
            callback(err);
          });
        });
      });
    }
  }

  function compile(src, options, callback) {
    var srcType = extension.exec(src)[1]
      , dest;

    for (var destType in compilers) {
      if (srcType in destType) {
        dest = src.replace(extension, "." + destType);
        _compileFile(src, dest, destType[srcType], options, callback);
        return;
      }
    }
    callback(new Error("No compiler for " + srcType));
  }

  function compileTarget(dest, options, callback) {
    var destType = extension.exec(dest)[1]
      , srcTypes, src, srcType;

    if (sourceCache[dest]) {
      srcType = sourceCache[dest];
      src = dest.replace(extension, "." + type);
      return _compileFile(src, dest, compilers[destType][srcType], options, callback);
    }

    function tryType(i) {
      srcType = srcTypes[i];
      if (srcType) {
        src = dest.replace(extension, "." + srcType);
        _compileFile(src, dest, compilers[destType][srcType], options, function(err) {
          if (err && err.code === 'ENOENT' && err.path === src) {
            tryType(i+1);
          } else {
            callback(err);
          }
        });
      } else {
        var error = new Error("No source found for " + dest);
        error.type = 'NOSOURCE';
        error.arguments = [dest, srcTypes];
        callback(error);
      }
    }

    srcTypes = Object.keys(compilers[destType] || {});
    tryType(0);
  }

  return {
    compile: compile,
    compileTarget: compileTarget
  };
};

/**
 * Compilation middleware
 */
exports.middleware = function(options) {
  var root = options.root || process.cwd();
  var compiler = exports(options);

  return function(req, res, next) {
    if ('GET' != req.method) {
      return next();
    }

    var path = parse(req.url).pathname;
    compiler.compileTarget(root + path, null, function(err) {
      if (err && err.type === "NOSOURCE") {
        next();
      } else {
        next(err);
      }
    });
  };
};


var modules = {};

var compilers = exports.compilers =
{ css:

  { styl: function(str, options, callback) {
      try {
        var stylus = modules.stylus || (modules.stylus = require("stylus"));
        stylus.render(str, options, callback);
      } catch (err) {
        callback(err);
      }
    }

  , less: function(str, options, callback) {
      try {
        var less = modules.less || (modules.less = require("less"));
        less.render(str, options, function(err, css) {
          makeLessErrorSexy(err);
          callback(err, css);
        });
      } catch (err) {
        makeLessErrorSexy(err);
        callback(err);
      }
    }
  }

, js:

  { coffee: function(str, options, callback) {
      try {
        var coffee = modules.coffee || (modules.coffee = require("coffee-script"));
        callback(null, coffee.compile(str, options));
      } catch (err) {
        callback(err);
      }
    }
  }

, html:

  { jade: function(str, options, callback) {
      try {
        var jade = modules.jade || (modules.jade = require("jade"))
          , template = jade.compile(str, options);
        callback(null, template());
      } catch (err) {
        callback(err);
      }
    }
  }
};

/**
 * Let's emulate stylus errors to make the less errors a bit more useful.
 * Heavily dependent on less error quirks.
 */
function makeLessErrorSexy(err) {
  if (err && err.toString === Object.prototype.toString) {
    err.toString = function() {
      var error = [];
      var nrSize = (this.line + 1).toString().length;
      error.push((this.type || this.name) + ": " + this.filename);
      this.line && (error[0] += ":" + this.line);
      if (this.extract) {
        this.extract[0] && error.push("  " + pad(this.line-1, nrSize) + "| " + this.extract[0]);
        this.extract[1] && error.push("> " + pad(this.line, nrSize) + "| " + this.extract[1]);
        this.extract[2] && error.push("  " + pad(this.line+1, nrSize) + "| " + this.extract[2]);
      }
      error.push("");
      error.push(this.message);
      error.push("");
      error.push(this.stack);
      return error.join("\n");
    };
  }

  function pad(integer, num) {
    var str = integer.toString()
    return Array(num-str.length).join(' ') + str;
  }
}
