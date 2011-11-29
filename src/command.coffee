fs           = require 'fs'
path         = require 'path'
commander    = require 'commander'
CoffeeScript = require 'coffee-script'
{spawn, exec}  = require 'child_process'

validateArgs = ->
  valid = true
  if commander.args.length is 0
    console.error "You need to specify a coffin template to act on."
    valid = false
  if commander.validate? or commander.createStack? or commander.updateStack?
    if commander.print?
      console.error "I can't run that command if you're just printing to the console."
      valid = false
    if not process.env.AWS_CLOUDFORMATION_HOME and not commander['cfn-home']?
      console.error "Either an AWS_CLOUDFORMATION_HOME environment variable or a --cfnHome switch is required."
      valid = false
  if not valid
    process.stdout.write commander.helpInformation()
    process.exit 0

compileTemplate = (source, callback) =>
  pre = "require('coffin') ->\n"
  fs.readFile source, (err, code) =>
    if err
      console.error "#{source} not found"
      process.exit 1
    tabbedLines = ('  ' + line for line in code.toString().split '\n')
    tabbedLines.push '  return'
    code = tabbedLines.join '\n'
    code = pre + code
    compiled = CoffeeScript.compile code, {source, bare: true}
    template = eval compiled
    templateString = if commander.pretty then JSON.stringify template, null, 2 else JSON.stringify template
    callback? templateString

writeJsonTemplate = (source, json, callback) ->
  base = commander.output || path.dirname source
  filename  = path.basename(source, path.extname(source)) + '.template'
  templatePath = path.join base, filename
  write = ->
    json = ' ' if json.length <= 0
    fs.writeFile templatePath, json, (err) ->
      console.err err.message if err
      console.log "\u26B0 #{templatePath}"
      callback? templatePath
  path.exists base, (exists) ->
    if exists then write() else exec "mkdir -p #{base}", write

buildCfnPath = ->
  cfnHome = commander['cfn-home'] || process.env.AWS_CLOUDFORMATION_HOME
  return path.normalize "#{cfnHome}/bin"

validateTemplate = (templatePath, callback) =>
  validateExec = "cfn-validate-template --template-file #{templatePath}"
  exec "#{buildCfnPath()}/#{validateExec}", (err) ->
    if not err
      console.log "\u26B0 #{templatePath} is valid"
    callback?()

commander.version '0.0.2'
commander.usage '[options] <coffin template>'

commander.option '-o, --output [dir]', 'Directory to output compiled file(s) to'
commander.option '-p, --pretty', 'Add spaces and stuff to the resulting json to make it a little prettier'
commander.option '--cfn-home [dir]', 'The home of your AWS Cloudformation tools. Defaults to your AWS_CLOUDFORMATION_HOME environment variable.'

printCommand = commander.command 'print [template]'
printCommand.description 'Print the compiled template.'
printCommand.action (template) ->
  validateArgs()
  compileTemplate template, (compiled) ->
    console.log compiled

validateCommand = commander.command 'validate [template]'
validateCommand.description 'Validate the compiled template. Either an AWS_CLOUDFORMATION_HOME environment variable or a --cfn-home switch is required.'
validateCommand.action (template) ->
  validateArgs()
  compileTemplate template, (compiled) ->
    writeJsonTemplate template, compiled, (fullCompiledPath) ->
      validateTemplate fullCompiledPath

stackCommand = commander.command 'stack [name] [template]'
stackCommand.description 'Create or update the named stack using the compiled template.'
stackCommand.action (name, template) ->
  validateArgs()
  console.log "todo: check to see if '#{name}' stack exists, either create or update based on '#{template}'"

compileCommand = commander.command 'compile [template]'
compileCommand.description 'Compile and write the template. The output file will have the same name as the coffin template plus a shiny new ".template" extension.'
compileCommand.action (template) ->
  validateArgs()
  compileTemplate template, (compiled) ->
    writeJsonTemplate template, compiled

module.exports.run = ->
  commander.parse process.argv

