fs = require "fs"

paramNames = []
INDENT = "  "

convertToArgs = (string) ->
  string.replace("[", "").replace("]", "").replace(/\n$/, "")

CFN_FUNCS = {
  "Fn::Base64": (obj, level, parentIsObj) ->
    "@Base64(#{convertJson obj["Fn::Base64"], level, parentIsObj})"

  "Fn::FindInMap": (obj, level, parentIsObj) ->
    string = convertJson obj["Fn::FindInMap"], level, parentIsObj
    "@FindInMap(#{convertToArgs string})"

  "Fn::GetAtt": (obj, level, parentIsObj) ->
    string = convertJson obj["Fn::GetAtt"], level, parentIsObj
    "@GetAtt(#{convertToArgs string})"

  "Fn::GetAZs": (obj, level, parentIsObj) ->
    "@GetAZs(#{convertJson obj["Fn::GetAZs"], level, parentIsObj})"

  "Fn::Join": (obj, level, parentIsObj) ->
    join = obj["Fn::Join"]
    string = convertJson join[1], level, parentIsObj
    "@Join(\"#{escapeString join[0]}\", #{string.replace(/\n$/, "")})"

  "Ref": (obj) ->
    if paramNames.indexOf(obj.Ref) > -1
      "@Params.#{obj.Ref}"
    else if obj.Ref == "AWS::Region"
      "@Region"
    else if obj.Ref == "AWS::StackName"
      "@StackName"
    else
      "@Resources.#{obj.Ref}"
}


indent = (text, times) ->
  front = ""
  for i in [0..times]
    front += INDENT
  return front + text

convertArray = (arr, level = 0, parentIsArray) ->
  if arr.length > 5 or typeof arr[0] is "object" then addNewline = true else addNewline = false
  output = "["
  if addNewline
    output += "\n"

  i = arr.length
  for val in arr
    if addNewline
      output += indent "#{convertJson val, level + 1, true}\n", level
    else 
      if --i
        output += "#{convertJson val, level}, "
      else
        output += convertJson val, level

  end = "]\n"
  if parentIsArray
    end = "]"

  if addNewline
    end = indent(end, level - 1)

  output += end

  return output

isFunction = (obj) ->
  for fun in Object.keys(CFN_FUNCS)
    return true if obj[fun]
  return false

convertFunction = (obj, level, parentIsObj) ->
  output = null
  for cfn, fun of CFN_FUNCS
    if obj[cfn]
      output = fun obj, level, parentIsObj

  return output

convertObj = (obj, level = 0, parentIsObj) ->
  return indent convertFunction(obj, level, parentIsObj) if isFunction obj
  if parentIsObj
    output = "\n"
  else
    output = ""
  keyLength = Object.keys(obj).length
  for key, val of obj
    if key.match /\W/
      key = "\"#{key}\""
    output += indent "#{key} : #{convertJson val, level + 1, true}", level
    if --keyLength
      output += "\n"
  return output

escapeString = (string) ->
  string
    .replace("\n", "\\n")
    .replace(/'/g, "\\'")
    .replace(/"/g, '\\"')

convertJson = (obj, level = 0, parentIsObj) ->
  if Array.isArray(obj)
    convertArray obj, level, parentIsObj
  else if typeof obj is "object"
    convertObj obj, level, parentIsObj
  else if typeof obj is "string"
    # preserve newlines in original source by escaping them
    "\"#{escapeString obj}\""
  else if typeof obj is "number"
    obj

checkForParams = (obj) ->
  if obj and Object.keys(obj).length 
    true
  else
    false

convertParam = (name, val) ->
  throw new Error "type is required for Param #{name}" if not val.Type
  paramNames.push name
  output = null
  if val.Description
    output = 
      """
      @Param.#{val.Type} \"#{name}\", \"#{val.Description}\"
      """
  else
    output = 
      """
      @Param.#{val.Type} \"#{name}\"
      """

  delete val.Type
  delete val.Description
  if checkForParams val
    output += ",\n"
    output += convertJson val
  return output + "\n\n"

convertMapping = (name, val) ->
  output = 
    """
    @Mapping \"#{name}\",

    """
  output += convertJson val
  return output + "\n\n"

convertResource = (name, val) ->
  throw new Error "missing type for resource with #{name}" if not val.Type
  output = 
    """
    @#{val.Type.replace /::/g, "."} \"#{name}\"
    """
  if val.Metadata
    delete val.Type
    if checkForParams val
      output += ",\n"
      output += convertJson val
  else 
    if checkForParams val.Properties
      output += ",\n"
      output += convertJson val.Properties

  return output + "\n\n"


convertOutput = (name, val) ->
  throw new Error "missing value for output with #{name}" if not val.Value
  if val.Description
    output = 
      """
      @Output \"#{name}\", \"#{val.Description}\",

      """
  else
    output = 
      """
      @Output \"#{name}\",

      """

  output += convertJson val.Value

  return output + "\n\n"


convertTopLevel = (params, converter) ->
  output = ""
  for name, val of params
    output += converter name, val

  return output

createForwardDeclrations = (resources) ->
  output = ""
  for res, val of resources
    output += "@DeclareResource(\"#{res}\")\n"

  output
    

convertToCoffin = (templateObj) ->
  output = ""
  output += createForwardDeclrations templateObj.Resources
  for key, val of templateObj
    switch key
      when "AWSTemplateFormatVersion"
        # don't care about doing anything here
        break
      when "Description"
        output += "@Description \"#{val}\"\n\n"
      when "Parameters"
        output += convertTopLevel val, convertParam
      when "Mappings"
        output += convertTopLevel val, convertMapping
      when "Resources"
        output += convertTopLevel val, convertResource
      when "Outputs"
        output += convertTopLevel val, convertOutput
      else
        console.log "don't have key #{key}"

  return output

module.exports = convertToCoffin
