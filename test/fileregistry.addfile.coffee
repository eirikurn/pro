assert        = require 'assert'
sinon         = require 'sinon'
FileRegistry  = require '../src/fileregistry'
worker        = require '../src/worker'



describe 'FileRegistry.addFile', ->
  workerQueueStub = null
  registry = null
  queueJob = sinon.stub().yields(null, { dependencies: [] })
  queueJob.withArgs('compile', sinon.match(source: 'tmp/withLayout.jade'))
          .yields(null, { dependencies: ['tmp/withLayout.jade', 'tmp/_layout.jade'] })
  queueJob.withArgs('compile', sinon.match(source: 'tmp/fails.jade'))
          .yields(new Error("Test error"))
  
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
    registry.addFile "tmp/withLayout.jade", {}, (e) ->

      assert.deepEqual(registry.dependencies["tmp/withLayout.html"], ["tmp/withLayout.jade", "tmp/_layout.jade"])
      cb()


  it 'forwards compile errors', (cb) ->
    registry.addFile "tmp/fails.jade", {}, (e) ->

      assert(e, "Didn't cause error")
      cb()
  
  it 'does not build private files'