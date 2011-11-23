vows   = require 'vows'
assert = require 'assert'
fs     = require 'fs'
path   = require 'path'

@assertListsEqual = (actualList, expectedList) ->
  assert.equal actualList.length, expectedList.length
  for key, val of expectedList
    for k, v of val.Properties
      assert.deepEqual actualList[key].Properties[k], v
    expected = {}
    expected[key] = val
    actual = {}
    actual[key] = actualList[key]
    assert.deepEqual actual, expected
  assert.deepEqual expectedList, actualList

suite = vows.describe 'WordPress Template Test Suite'
suite.addBatch
  'when parsing WordPressTemplate.coffee':
    topic: ->
      raw = ''
      input = fs.createReadStream path.normalize '../examples/WordPress-1.0.0.template.original'
      input.on 'data', (d) =>
        raw += "#{d}"
      input.on 'end', =>
        generatedTemplate = require('../examples/WordPress-1.0.0.template.coffee')
        originalTemplate = JSON.parse(raw)
        console.log "generatedTemplate - #{JSON.stringify(generatedTemplate).length}, originalTemplate - #{JSON.stringify(originalTemplate).length}"
        @callback originalTemplate, generatedTemplate
      return
    'Descriptions are the same': (originalTemplate, generatedTemplate) =>
      return if originalTemplate is null or generatedTemplate is null
      assert.equal generatedTemplate.Description, originalTemplate.Description
    'Parameters are the same': (originalTemplate, generatedTemplate) =>
      return if originalTemplate is null or generatedTemplate is null
      @assertListsEqual generatedTemplate.Parameters, originalTemplate.Parameters
    'Resources are the same': (originalTemplate, generatedTemplate) =>
      return if originalTemplate is null or generatedTemplate is null
      @assertListsEqual generatedTemplate.Resources, originalTemplate.Resources
    'Outputs are the same': (originalTemplate, generatedTemplate) =>
      return if originalTemplate is null or generatedTemplate is null
      @assertListsEqual generatedTemplate.Outputs, originalTemplate.Outputs
suite.run()
