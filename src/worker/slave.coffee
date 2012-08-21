# Needs to be imported first to override node's fs methods before other modules cache them.
monitor = require './fs-monitor'

exports.jobs = require './jobs'

currentJob = null

##
# Gets a message of the form:
# { job: "jobName", data: { key: value } }
#
# Sends the result of the job back to parent process with the form:
# { status: "success", result: {} }
# or an error:
# { status: "error", error: {name: "...", message: "...", stack: "..."} }
exports.handleMessage = (m) ->
  if currentJob
    throw new Error("Worker received a job while still processing another job. Something is broken.")

  currentJob = exports.jobs[m.job]

  unless currentJob
    console.log "Unknown job #{m.job}"
    return

  currentJob m.data, (err, result) ->
    if err
      process.send { status: "error", error: {stack: err.stack, message: err.message, name: err.name} }
    else
      process.send { status: "success", result: result }
    currentJob = null


process.on 'message', exports.handleMessage
