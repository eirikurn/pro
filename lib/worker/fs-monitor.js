// Generated by CoffeeScript 1.3.3
(function() {
  var accessed, filter, fs, fsLevel, h, hooked, ignored, minimatch, patchFunction, _i, _j, _len, _len1,
    __slice = [].slice;

  fs = require('fs');

  minimatch = require('minimatch');

  hooked = ["readFile", "readFileSync", "open", "openSync", "stat", "statSync", "exists", "existsSync", "createReadStream"];

  ignored = ["writeFile", "writeFileSync"];

  patchFunction = function(name, ignore) {
    var old;
    if (ignore == null) {
      ignore = false;
    }
    old = fs[name];
    return fs[name] = function() {
      var args, path, result;
      path = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      if (fsLevel++ === 0 && !ignore) {
        if (!filter || minimatch(path, filter)) {
          accessed[path] = (accessed[path] || 0) + 1;
        }
      }
      try {
        return result = old.apply(null, [path].concat(__slice.call(args)));
      } finally {
        fsLevel--;
      }
    };
  };

  for (_i = 0, _len = hooked.length; _i < _len; _i++) {
    h = hooked[_i];
    patchFunction(h);
  }

  for (_j = 0, _len1 = ignored.length; _j < _len1; _j++) {
    h = ignored[_j];
    patchFunction(h, true);
  }

  accessed = {};

  fsLevel = 0;

  filter = null;

  exports.clear = function() {
    return accessed = {};
  };

  exports.setFilter = function(f) {
    return filter = f;
  };

  exports.getAccessed = function() {
    return Object.keys(accessed);
  };

}).call(this);