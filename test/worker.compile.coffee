assert    = require 'assert'
fs        = require 'fs'
sinon     = require 'sinon'

jobs      = require '../src/worker/jobs'
compilers = require '../src/compilers'


describe 'jobs.compile', ->
  jobData = {source: 'tmp/source.test', target: 'tmp/target'}
  compilers.test = compile: null
  c = compilers.test

  before ->
    try fs.mkdirSync 'tmp'
    try fs.writeFileSync 'tmp/source.test', 'CONTENTS'

  after ->
    try fs.unlinkSync 'tmp/source.test'
    try fs.unlinkSync 'tmp/target'
    try fs.rmdirSync 'tmp'

  beforeEach ->
    c.compile = sinon.stub().yields(null, "RESULT")

  it 'runs compiler based on extension of source with its contents', (cb) ->

    jobs.compile jobData, (err, result) ->
      sinon.assert.calledOnce c.compile
      sinon.assert.calledWith c.compile, "CONTENTS"
      assert.equal fs.readFileSync('tmp/target'), "RESULT"
      cb()

  it 'always records source file as dependency', (cb) ->

    jobs.compile jobData, (err, result) ->
      assert.deepEqual {dependencies: ['tmp/source.test']}, result
      cb()

  it 'records access to other files', (cb) ->
    c.compile = (f,o,cb) ->
      try fs.readFileSync "tmp/extra"
      cb(null, "RESULT")

    jobs.compile jobData, (err, result) ->
      assert.deepEqual {dependencies: ['tmp/source.test', 'tmp/extra']}, result
      cb()

  it 'forwards asynchronous errors', (cb) ->
    c.compile.yields(new Error("Test"))

    jobs.compile jobData, (err, result) ->
      assert err != null, "didn't send error"
      cb()

  it 'forwards synchronous errors', (cb) ->
    c.compile.throws(new Error("Test"))

    jobs.compile jobData, (err, result) ->
      assert err != null, "didn't send error"
      cb()