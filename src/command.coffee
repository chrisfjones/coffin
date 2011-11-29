fs           = require 'fs'
path         = require 'path'
commander    = require 'commander'
CoffeeScript = require 'coffee-script'
{spawn, exec}  = require 'child_process'

commander.version '0.0.2'
commander.usage '[options] <coffin template>'
commander.option '-o, --output [dir]', 'Directory to output compiled file(s) to'
commander.option '--pretty', 'Add spaces and stuff to the resulting json to make it a little prettier'
commander.option '-p --print', 'Print the compiled template'
commander.option '--cloudFormationHome [dir]', 'The home of your AWS Cloudformation tools. Defaults to your AWS_CLOUDFORMATION_HOME environment variable.'
commander.option '--validate', 'Validates the generated template. Either an AWS_CLOUDFORMATION_HOME environment variable or a --cloudFormationHome switch is required.'
commander.parse process.argv

exports = module.exports.run = ->
  if !validateArgs()
    commander.usage()
    return
  pre = "require('coffin') ->\n"
  for source in commander.args
    fs.readFile source, (err, code) ->
      if err
        console.error "#{source} not found"
        process.exit 1
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
        writeJsonTemplate source, templateString, base, commander.validate?

validateArgs = ->
  if commander.args.length is 0
    console.error "You need to specify a coffin template to act on."
    return false
  if commander.validate?
    if commander.print?
      console.error "I can't validate if you're just printing to the console."
      return false
    if not process.env.AWS_CLOUDFORMATION_HOME and not commander.cloudFormationHome?
      console.error "Either an AWS_CLOUDFORMATION_HOME environment variable or a --cloudFormationHome switch is required to validate."
      return false
  return true

writeJsonTemplate = (source, json, base, validate) ->
  filename  = path.basename(source, path.extname(source)) + '.template'
  templatePath = path.join base, filename
  write = ->
    json = ' ' if json.length <= 0
    fs.writeFile templatePath, json, (err) ->
      console.err err.message if err
      console.log "\u26B0 #{templatePath}"
      if validate
        cfnPath = path.normalize "#{process.env.AWS_CLOUDFORMATION_HOME}/bin"
        validateCommand = "cfn-validate-template --template-file #{templatePath}"
        exec "#{cfnPath}/#{validateCommand}", (err) ->
          if not err
            console.log "\u26B0 #{templatePath} is valid"
  path.exists base, (exists) ->
    if exists then write() else exec "mkdir -p #{base}", write
