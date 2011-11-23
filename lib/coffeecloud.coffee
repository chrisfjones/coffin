class CloudFormationTemplateContext
  constructor: ->
    @_resources = {}
    @_parameters = {}
    @_outputs = {}
    @_description = null
    @Params = {}
    @Resources = {}
    @AWS =
      AutoScaling:
        AutoScalingGroup: null
        LaunchConfiguration: null
        ScalingPolicy: null
      CloudWatch:
        Alarm: null
      EC2:
        SecurityGroup: null
      ElasticLoadBalancing:
        LoadBalancer: null
      SNS:
        Topic: null
      RDS:
        DBSecurityGroup: null
        DBInstance: null
    @Param =
      String: (name, args...) => @_paramByType 'String', name, args[0], args[1]
      Number: (name, args...) => @_paramByType 'Number', name, args[0], args[1]
      CommaDelimitedList: (name, args...) => @_paramByType 'CommaDelimitedList', name, args[0], args[1]
    @_buildCall null, null, 'AWS', @AWS

  _paramByType: (type, name, args...) =>
    result = {}
    if typeof args[1] is 'object'
      result[name] = args[1]
      result[name].Description = args[0]
    else if typeof args[0] is 'object'
      result[name] = args[0]
    else if typeof args[0] is 'string'
      result[name] = Description: args[0]
    result[name].Type = type
    @_set result, @_parameters
    @Params[name] = Ref: name

  _buildCall: (parent, lastKey, awsType, leaf) =>
    if leaf?
      for key, val of leaf
        @_buildCall leaf, key, "#{awsType}::#{key}", val
      return
    parent[lastKey] = (name, props) =>
      @_resourceByType awsType, name, props

  # todo: this cheesy forward decl thing shouldn't be necessary
  DeclareResource: (name) =>
    @Resources[name] ?= Ref: name

  _resourceByType: (type, name, props) =>
    result = {}
    result[name] =
      Type: type
      Properties: props
    @_set result, @_resources
    @DeclareResource name

  _set: (source, target) ->
    for key, val of source
      target[key] = val

  Output: (name, args...) =>
    result = {}
    if args.length is 1
      result[name] =
        Value: args[0]
    if args.length is 2
      result[name] =
        Description: args[0]
        Value: args[1]
    @_set result, @_outputs

  Description: (d) => @_description = d

  #utility functions
  Join: (delimiter, args...) ->
    'Fn::Join': [ delimiter, args ]
  FindInMap: (args...) ->
    'Fn::FindInMap': args
  GetAtt: (args...) ->
    'Fn::GetAtt': args
  Base64: (arg) ->
    'Fn::Base64': arg
  GetAZs: (arg) ->
    'Fn::GetAZs': arg
  Region: 'AWS::Region'
  StackName: 'AWS::StackName'

module.exports.CloudFormationTemplateContext = CloudFormationTemplateContext

module.exports = (func) ->
  context = new CloudFormationTemplateContext
  func.apply context, [context]
  template =
    AWSTemplateFormatVersion: '2010-09-09'
    Description:              context._description
    Parameters:               context._parameters
    Resources:                context._resources
    Outputs:                  context._outputs
