# Dependencies
files     = require './files'
utils     = require './utils'

##
# Compiled file types.
#
# * key:          the file extension of the source file
# * compilesTo:   the target file extension
# * fileStrategy: a class that handles dependency tracking and complex compilations
# * compile:      a function that receives source file contents and should call
#                 its callback with the target file contents
##
compilers = module.exports =

  jade:
    compilesTo: 'html'
    supportsBody: true
    fileStrategy: files.TemplateFile
    compile: (str, options, cb) ->
      @jade or= require "jade"
      str = @jade.compile(str, options)(options)
      cb(null, str)

  md:
    compilesTo: 'html'
    fileStrategy: files.TemplateFile
    compile: (str, options, cb) ->
      @markdown or= require("markdown").markdown
      str = @markdown.toHTML(str)
      cb(null, str)

  styl:
    compilesTo: 'css'
    fileStrategy: files.StylesheetFile
    compile: (str, options, cb) ->
      @stylus or= require "stylus"
      @stylus.render(str, options, cb)

  less:
    compilesTo: 'css'
    fileStrategy: files.LessFile
    compile: (str, options, cb) ->
      @less or= require "less"
      @less.render str, options, cb

  coffee:
    compilesTo: 'js'
    fileStrategy: files.File
    compile: (str, options, cb) ->
      @coffee or= require "coffee-script"
      cb null, @coffee.compile(str, options)

  default:
    fileStrategy: files.File
    encoding: null
    compile: (str, options, cb) -> cb(null, str)

  ##
  # A utility function to get the compiler for the specified source file.
  forFile: (file) ->
    ext = utils.extname(file)
    compiler = compilers[ext] or compilers.default
    return compiler