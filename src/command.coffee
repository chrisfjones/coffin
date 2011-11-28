fs           = require 'fs'
path         = require 'path'
commander    = require 'commander'
CoffeeScript = require 'coffee-script'
{spawn, exec}  = require 'child_process'

commander.version '0.0.1'
commander.usage '[options] <coffin template>'
commander.option '-o, --output [dir]', 'Directory to output compiled file(s) to'
commander.option '--pretty', 'Add spaces and stuff to the resulting json to make it a little prettier'
commander.option '-p --print', 'Print the compiled template'
commander.parse process.argv

exports = module.exports.run = ->
  pre = "require('./coffin') ->\n"
  for source in commander.args
    fs.readFile source, (err, code) ->
      throw err if err
      base = commander.output || path.dirname source
      tabbedLines = ('  ' + line for line in code.toString().split '\n')
      tabbedLines.push '  return'
      code = tabbedLines.join '\n'
      code = pre + code
      compiled = CoffeeScript.compile code, {source, bare: true}
      template = eval compiled
      templateString = if commander.pretty then JSON.stringify template, null, 2 else JSON.stringify template
      if commander.print
        console.log templateString
      else
        writeJsonTemplate source, templateString, base

writeJsonTemplate = (source, json, base) ->
  filename  = path.basename(source, path.extname(source)) + '.template'
  templatePath = path.join base, filename
  write = ->
    json = ' ' if json.length <= 0
    fs.writeFile templatePath, json, (err) ->
      console.err err.message if err
      console.log "\u26B0 #{templatePath}"
  path.exists base, (exists) ->
    if exists then write() else exec "mkdir -p #{base}", write
