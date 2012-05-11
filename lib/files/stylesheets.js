(function() {
  var File, LessFile, StylesheetFile, pad;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  File = require('./index').File;

  StylesheetFile = (function() {

    __extends(StylesheetFile, File);

    function StylesheetFile() {
      StylesheetFile.__super__.constructor.apply(this, arguments);
    }

    return StylesheetFile;

  })();

  LessFile = (function() {

    __extends(LessFile, StylesheetFile);

    function LessFile() {
      LessFile.__super__.constructor.apply(this, arguments);
    }

    LessFile.prototype.compile = function(str, options, cb) {
      try {
        options.filename = this.path;
        return this.compiler.compile(str, options, function(err, str) {
          return cb(LessFile.patchError(err), str);
        });
      } catch (err) {
        return cb(LessFile.patchError(err));
      }
    };

    LessFile.patchError = function(err) {
      if (err && err.toString === Object.prototype.toString) {
        err.toString = function() {
          var error, nrSize;
          error = [];
          nrSize = (this.line + 1).toString().length;
          error.push((this.type || this.name) + ": " + this.filename);
          if (this.line) error[0] += ":" + this.line;
          if (this.extract) {
            if (this.extract[0]) {
              error.push("  " + pad(this.line - 1, nrSize) + "| " + this.extract[0]);
            }
            if (this.extract[1]) {
              error.push("> " + pad(this.line, nrSize) + "| " + this.extract[1]);
            }
            if (this.extract[2]) {
              error.push("  " + pad(this.line + 1, nrSize) + "| " + this.extract[2]);
            }
          }
          error.push("");
          error.push(this.message);
          error.push("");
          error.push(this.stack);
          return error.join("\n");
        };
      }
      return err;
    };

    return LessFile;

  })();

  exports.StylesheetFile = StylesheetFile;

  exports.LessFile = LessFile;

  pad = function(integer, num) {
    var str;
    str = integer.toString();
    return Array(num - str.length).join(' ') + str;
  };

}).call(this);
