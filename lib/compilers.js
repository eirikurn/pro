(function() {
  var files;

  files = require('./files');

  module.exports = {
    jade: {
      compilesTo: 'html',
      supportsBody: true,
      fileStrategy: files.TemplateFile,
      compile: function(str, options, cb) {
        this.jade || (this.jade = require("jade"));
        str = this.jade.compile(str, options)(options);
        return cb(null, str);
      }
    },
    md: {
      compilesTo: 'html',
      fileStrategy: files.TemplateFile,
      compile: function(str, options, cb) {
        this.markdown || (this.markdown = require("markdown").markdown);
        str = this.markdown.toHTML(str);
        return cb(null, str);
      }
    },
    styl: {
      compilesTo: 'css',
      fileStrategy: files.StylesheetFile,
      compile: function(str, options, cb) {
        this.stylus || (this.stylus = require("stylus"));
        return this.stylus.render(str, options, cb);
      }
    },
    less: {
      compilesTo: 'css',
      fileStrategy: files.LessFile,
      compile: function(str, options, cb) {
        this.less || (this.less = require("less"));
        return this.less.render(str, options, cb);
      }
    },
    coffee: {
      compilesTo: 'js',
      fileStrategy: files.File,
      compile: function(str, options, cb) {
        this.coffee || (this.coffee = require("coffee-script"));
        return cb(null, this.coffee.compile(str, options));
      }
    },
    "default": {
      fileStrategy: files.File,
      encoding: null,
      compile: function(str, options, cb) {
        return cb(null, str);
      }
    }
  };

}).call(this);
