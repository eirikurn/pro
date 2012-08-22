// An ugly hack to have pro work when running directly from coffee src
// since child_process.fork only supports js files.

// In development it will load this file which enables coffee and wraps the real module.
// In production this file doesn't exist and the real module (then compiled to js) is run directly.
// ... sorry tj


// Turn on coffee-script
require('coffee-script');

module.exports = require('./slave.coffee');