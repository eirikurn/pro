assert        = require 'assert'
child_process = require 'child_process'
events        = require 'events'
sinon         = require 'sinon'
worker        = require '../src/worker'


class ProcessStub extends events.EventEmitter
  constructor: ->
    @pid = ProcessStub.next_pid++

  send: sinon.spy (msg) ->
    setTimeout =>
      @emit 'message', {status: 'success', result: msg.data}
    , 10

  connected: true
  killed: false

ProcessStub.next_pid = 1


describe 'WorkerQueue', ->
  clock = null
  
  before ->
    sinon.stub child_process, 'fork', -> new ProcessStub()
    clock = sinon.useFakeTimers()

  after ->
    child_process.fork.restore()
    clock.restore()

  beforeEach ->
    ProcessStub::send.reset()
    child_process.fork.reset()

  it 'starts workers', ->
    queue = new worker.WorkerQueue(2)
    sinon.assert.calledTwice child_process.fork

  it 'sends a queued job to the first worker', (cb) ->
    queue = new worker.WorkerQueue(2)

    queue.queueJob 'test', '', cb
    sinon.assert.calledOnce ProcessStub::send

    clock.tick 10

  it 'queues up jobs and runs them in order', ->
    queue = new worker.WorkerQueue(2)
    cb = sinon.spy()

    queue.queueJob 'test', '1', cb
    clock.tick 2
    queue.queueJob 'test', '2', cb
    clock.tick 2
    queue.queueJob 'test', '3', cb
    clock.tick 2
    queue.queueJob 'test', '4', cb
    clock.tick 2

    # After 8 ticks, first two jobs should be running but nothing finished
    sinon.assert.callCount ProcessStub::send, 2
    sinon.assert.callCount cb,                0

    # After 12 ticks, second two jobs should have started because first two are finished
    clock.tick 4
    sinon.assert.callCount ProcessStub::send, 4
    sinon.assert.callCount cb,                2

    # After 22 ticks, all jobs should be finished
    clock.tick 10
    sinon.assert.callCount cb,                4

    # Check the order of the jobs
    assert.deepEqual cb.args, [[null, '1'], [null, '2'], [null, '3'], [null, '4']]

