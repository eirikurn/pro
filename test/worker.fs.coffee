monitor = require '../src/worker/fs-monitor'
fs = require 'fs'
assert = require 'assert'

describe 'fs-monitor', ->
  before ->
    try fs.mkdirSync 'tmp'
    try fs.writeFileSync 'tmp/file'

  after ->
    try fs.unlinkSync 'tmp/file'
    try fs.rmdirSync 'tmp'

  beforeEach ->
    monitor.clear()


  it 'should log access to non-existent files', ->
    try fs.readFileSync 'tmp/does_not_exist'

    assert.deepEqual ['tmp/does_not_exist'], monitor.getAccessed()


  it 'should log multiple accesses once', ->
    fs.readFileSync 'tmp/file'
    fs.readFileSync 'tmp/file'
    assert.deepEqual ['tmp/file'], monitor.getAccessed()


  describe 'when filtered', ->
    before ->
      monitor.setFilter 'tmp/**'

    after ->
      monitor.setFilter null


    it 'should log access to files that match filter', ->
      fs.readFileSync 'tmp/file'
      assert.deepEqual ['tmp/file'], monitor.getAccessed()

    it 'should not log access to files that do not match filter', ->
      try fs.readFileSync 'fake/file'
      assert.deepEqual [], monitor.getAccessed()


  describe 'with default filters', ->
    it 'should not log access to hidden files', ->
      try fs.readFileSync 'tmp/.hidden'
      assert.deepEqual [], monitor.getAccessed()

    it 'should not log access to files in hidden folders', ->
      try fs.readFileSync 'tmp/.hidden/file'
      assert.deepEqual [], monitor.getAccessed()

    it 'should not log access to files in node_modules', ->
      try fs.readFileSync './node_modules/module'
      assert.deepEqual [], monitor.getAccessed()


  describe 'should log access from', ->
    it 'fs.readFile', (cb) ->
      fs.readFile 'tmp/file', ->
        assert.deepEqual ['tmp/file'], monitor.getAccessed()
        cb()

    it 'fs.readFileSync', ->
      fs.readFileSync 'tmp/file'
      assert.deepEqual ['tmp/file'], monitor.getAccessed()

    it 'fs.open', (cb) ->
      fs.open 'tmp/file', 'r', ->
        assert.deepEqual ['tmp/file'], monitor.getAccessed()
        cb()

    it 'fs.openSync', ->
      fs.openSync 'tmp/file', 'r'
      assert.deepEqual ['tmp/file'], monitor.getAccessed()

    it 'fs.stat', (cb) ->
      fs.stat 'tmp/file', ->
        assert.deepEqual ['tmp/file'], monitor.getAccessed()
        cb()

    it 'fs.statSync', ->
      fs.statSync 'tmp/file'
      assert.deepEqual ['tmp/file'], monitor.getAccessed()

    it 'fs.exists', (cb) ->
      fs.exists 'tmp/file', ->
        assert.deepEqual ['tmp/file'], monitor.getAccessed()
        cb()

    it 'fs.existsSync', ->
      fs.existsSync 'tmp/file'
      assert.deepEqual ['tmp/file'], monitor.getAccessed()

    it 'fs.createReadStream', ->
      fs.createReadStream 'tmp/file'
      assert.deepEqual ['tmp/file'], monitor.getAccessed()

  # BUG: Some write functions call read functions behind the scenes.
  # Let's make sure they get ignored. Are there more?
  describe 'should not log access from', ->
    it 'fs.writeFile', (cb) ->
      fs.writeFile 'tmp/file', 'test', ->
        assert.deepEqual [], monitor.getAccessed()
        cb()

    it 'fs.writeFileSync', ->
      fs.writeFileSync 'tmp/file', 'test'
      assert.deepEqual [], monitor.getAccessed()

