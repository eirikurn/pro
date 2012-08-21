assert    = require 'assert'
fs        = require 'fs'
sinon     = require 'sinon'

jobs      = require '../src/worker/jobs'
compilers = require '../src/compilers'


compiler = sinon.spy (file, opts, cb) ->
  if opts?.extraFile
    try fs.readFileSync opts.extraFile

  if opts?.shouldFail
    cb(new Error("Test"))
  else
    cb(null, "RESULT")

compilers.test = compile: compiler


describe 'jobs.compile', ->
  before ->
    try fs.mkdirSync 'tmp'
    try fs.writeFileSync 'tmp/source.test', 'CONTENTS'

  after ->
    try fs.unlinkSync 'tmp/source.test'
    try fs.unlinkSync 'tmp/target'
    try fs.rmdirSync 'tmp'

  it 'runs compiler based on extension of source with its contents', (cb) ->
    jobData = {source: 'tmp/source.test', target: 'tmp/target'}

    jobs.compile jobData, (err, result) ->
      sinon.assert.calledOnce compiler
      sinon.assert.calledWith compiler, "CONTENTS"
      assert.deepEqual result, {dependencies: []}
      assert.equal fs.readFileSync('tmp/target'), "RESULT"
      cb()

  it 'monitors accessed files', (cb) ->
    jobData = {source: 'tmp/source.test', target: 'tmp/target', options: {extraFile: 'tmp/extra'}}

    jobs.compile jobData, (err, result) ->
      assert.deepEqual {dependencies: ['tmp/extra']}, result
      cb()

  it 'forwards raised errors', (cb) ->
    jobData = {source: 'tmp/source.test', target: 'tmp/target', options: {shouldFail: true}}

    jobs.compile jobData, (err, result) ->
      assert err != null, "didn't send error"
      cb()