child_process = require 'child_process'
path          = require 'path'

WORKER_COUNT = process.env.PRO_WORKERS || require('os').cpus().length

class exports.WorkerQueue
  constructor: (num_workers = WORKER_COUNT) ->
    @queue       = []
    @workers     = for i in [0...num_workers] then do =>
      worker = child_process.fork(path.join(__dirname, 'slave'))
      worker.on 'message', (msg) => @handleMessage(worker, msg)
      worker
    @freeWorkers = @workers[..]
    @activeJobs = {}

  queueJob: (jobName, data, cb) ->
    @queue.push [jobName, data, cb]
    @checkJobs()

  checkJobs: ->
    if @queue.length and @freeWorkers.length
      job = @queue.shift()
      worker = @freeWorkers.shift()
      worker.send { job: job[0], data: job[1] }
      @activeJobs[worker.pid] = job

  handleMessage: (worker, msg) ->
    job = @activeJobs[worker.pid]
    cb = job[2]
    if msg.status == 'error'
      cb msg.error
    else
      cb null, msg.result

    @freeWorkers.push worker
    @checkJobs()







