sinon  = require 'sinon'
assert = require 'assert'
slave  = require '../src/worker/slave'

describe 'slave.handleMessage', ->
  sendSpy     = process.send           = sinon.spy()
  testSuccess = slave.jobs.testSuccess = sinon.stub().yields(null, 42)
  testFailure = slave.jobs.testFailure = sinon.stub().yields(new Error("Test error"))



  it 'should call job with args', ->
    testSuccess.reset()

    slave.handleMessage job: 'testSuccess', data: "arg"

    sinon.assert.calledOnce testSuccess
    sinon.assert.calledWith testSuccess, "arg"

  it 'should return result to parent process', ->
    sendSpy.reset()

    slave.handleMessage job: 'testSuccess', data: null

    sinon.assert.calledOnce sendSpy
    sinon.assert.calledWith sendSpy, sinon.match({status: "success", result: 42})

  it 'should return errors to parent process', ->
    sendSpy.reset()

    slave.handleMessage job: 'testFailure', data: null

    sinon.assert.calledOnce sendSpy
    sinon.assert.calledWith sendSpy, sinon.match({status: "error", error: {name: "Error", message: "Test error"}})

  it 'does not support two jobs at once', ->
    # This job takes 100 ms
    slave.jobs.testDelayed = (data, cb) ->
      setTimeout ->
        cb()
      , 100

    # Let's run it in fake time.
    clock = sinon.useFakeTimers()
    slave.handleMessage job: 'testDelayed', data: null

    # Run a second job while first one is still running.
    clock.tick(50)
    assert.throws -> slave.handleMessage job: 'testSuccess', data: null

    # Let the delayed job finish.
    clock.tick(51)


