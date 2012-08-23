assert        = require 'assert'
sinon         = require 'sinon'
FileRegistry  = require '../src/fileregistry'
worker        = require '../src/worker'



describe 'FileRegistry.addFile', ->
  workerQueueStub = null
  registry = null
  queueJob = sinon.spy (job, data, cb) ->
    cb(null, { dependencies: ['tmp/file.jade', 'tmp/_layout.jade'] })
  
  before ->
    workerQueueStub = sinon.stub worker, 'WorkerQueue', -> { queueJob: queueJob }

  after ->
    workerQueueStub.restore()

  beforeEach ->
    queueJob.reset()
    registry = new FileRegistry(".", "_build")


  it 'queues compile job', (cb) ->
    registry.addFile "tmp/file.jade", {}, (e) ->

      sinon.assert.calledOnce queueJob

      expectedJob =
        source: "tmp/file.jade"
        target: "_build/tmp/file.html"
        options: { filename: "tmp/file.jade" }
      sinon.assert.calledWith queueJob, "compile", sinon.match(expectedJob)
      cb()

  it 'stores dependencies', (cb) ->
    registry.addFile "tmp/file.jade", {}, (e) ->

      assert.deepEqual(registry.dependencies["tmp/file.html"], ["tmp/file.jade", "tmp/_layout.jade"])
      cb()