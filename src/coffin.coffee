fs           = require 'fs'
vm           = require 'vm'
path         = require 'path'
CoffeeScript = require 'coffee-script'

class CloudFormationTemplateContext
  constructor: ->
    @_resources   = {}
    @_parameters  = {}
    @_mappings    = null
    @_outputs     = {}
    @_description = null
    @Params       = {}
    @Resources    = {}
    @Mappings     = {}
    @AWS =
      AutoScaling:
        AutoScalingGroup: null
        LaunchConfiguration: null
        ScalingPolicy: null
        Trigger: null
      CloudFormation:
        Stack: null
        WaitCondition: null
        WaitConditionHandle: null
      CloudFront:
        Distribution: null
      CloudWatch:
        Alarm: null
      EC2:
        EIP: null
        EIPAssociation: null
        Instance: null
        SecurityGroup: null
        SecurityGroupIngress: null
        Volume: null
        VolumeAttachment: null
      ElastiCache:
        CacheCluster: null
        ParameterGroup: null
        SecurityGroup: null
        SecurityGroupIngress: null
      ElasticBeanstalk:
        Application: null
        Environment: null
      ElasticLoadBalancing:
        LoadBalancer: null
      IAM:
        AccessKey: null
        Group: null
        Policy: null
        User: null
        UserToGroupAddition: null
      RDS:
        DBInstance: null
        DBSecurityGroup: null
      Route53:
        RecordSet: null
        RecordSetGroup: null
      S3:
        Bucket: null
        BucketPolicy: null
      SNS:
        Topic: null
        TopicPolicy: null
      SQS:
        Queue: null
        QueuePolicy: null
    @Param =
      String: (name, arg1, arg2) =>             @_paramByType 'String', name, arg1, arg2
      Number: (name, arg1, arg2) =>             @_paramByType 'Number', name, arg1, arg2
      CommaDelimitedList: (name, arg1, arg2) => @_paramByType 'CommaDelimitedList', name, arg1, arg2
    @_buildCall null, null, 'AWS', @AWS

  _paramByType: (type, name, arg1, arg2) =>
    result = {}
    if not arg1?
      result[name] = {}
    else if not arg2?
      result[name] = if typeof arg1 is 'string' then Description: arg1 else arg1
    else
      result[name] = arg2
      result[name].Description = arg1
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
    if props?.Metadata? or props?.Properties?
      props.Type = type
      result[name] = props
    else
      result[name] =
        Type: type
        Properties: props
    @_set result, @_resources
    @DeclareResource name

  _set: (source, target) ->
    for key, val of source
      target[key] = val

  Mapping: (name, map) =>
    @_mappings ?= {}
    result = {}
    result[name] = map
    @_set result, @_mappings

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

  Tag: (key, val) ->
    Key: key
    Value: val

  #utility functions
  Join: (delimiter, args...) ->
    if args.length is 1 and (args[0] instanceof Array)
      'Fn::Join': [ delimiter, args[0] ]
    else
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
  InitScript: (arg) ->
    if not path.existsSync(arg)
      text = arg
    else
      text = fs.readFileSync(arg).toString()
    chunks = []
    #todo: fix this abhoration of regex
    pattern = /((.|\n)*?)#{([^}?]+)}?((.|\n)*)/
    match = text.match pattern
    while match
      chunks.push match[1]
      compiled = CoffeeScript.compile match[3], {bare: true}
      chunks.push eval compiled
      text = match[4]
      match = text.match pattern
    chunks.push text if text and text.length > 0
    @Base64 @Join '', chunks

module.exports.CloudFormationTemplateContext = CloudFormationTemplateContext

module.exports = (func) ->
  context = new CloudFormationTemplateContext
  func.apply context, [context]
  template = AWSTemplateFormatVersion: '2010-09-09'
  template.Description = context._description if context._description?
  template.Parameters  = context._parameters
  template.Mappings    = context._mappings    if context._mappings?
  template.Resources   = context._resources
  template.Outputs     = context._outputs
  template

require('pkginfo')(module, 'version')
