{File} = require './index'

# Later this may include dependency searching.
class StylesheetFile extends File

# Less errors don't know a propper toString(). Let's teach
# them how stylus does it.
#
# Note: This is fairly coupled to current less behaviours.
class LessFile extends StylesheetFile
  compile: (str, options, cb) ->
    try
      options.filename = @path
      @compiler.compile str, options, (err, str) ->
        cb LessFile.patchError(err), str
    catch err
      cb LessFile.patchError(err)

  @patchError: (err) ->
    if err and err.toString == Object::toString
      err.toString = ->
        error = []
        nrSize = (@line + 1).toString().length
        error.push (@type or @name) + ": " + @filename
        error[0] += ":" + @line if @line
        if @extract
          error.push "  " + pad(@line-1, nrSize) + "| " + @extract[0] if @extract[0]
          error.push "> " + pad(@line, nrSize)   + "| " + @extract[1] if @extract[1]
          error.push "  " + pad(@line+1, nrSize) + "| " + @extract[2] if @extract[2]

        error.push ""
        error.push @message
        error.push ""
        error.push @stack
        return error.join "\n"

    return err

# Export file types defined here.
exports.StylesheetFile = StylesheetFile
exports.LessFile = LessFile

# A string padding helper
pad = (integer, num) ->
  str = integer.toString()
  return Array(num-str.length).join(' ') + str
