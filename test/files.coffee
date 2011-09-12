vows = require 'vows'
assert = require 'assert'
{fs} = require './'
{Compilers} = require '../lib/fileregistry'

{File} = require '../lib/files'

registry =
  target: "_build"
  fs: new fs
    "test.txt": ""
    "_private.jade": ""

vows.describe('Files').addBatch(
  'A plain txt file':
    topic: new File("test.txt", registry.fs._infoSync("test.txt"), Compilers.default, registry)

    'is not private': (file) -> assert.equal file.private, false
    'has a target path': (file) -> assert.equal file.targetPath, "_build/test.txt"
    'has a txt extension': (file) -> assert.equal file.extension, "txt"
    'depends on nothing': (file) -> assert.deepEqual file.dependsOn, []

  'A private file':
    topic: new File("_private.jade", registry.fs._infoSync("_private.jade"), Compilers.jade, registry)

    'is private': (file) -> assert.equal file.private, true
    'has no target path': (file) -> assert.isUndefined file.targetPath

).export(module)

