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
      String: (name, props) => @_paramByType 'String', name, props
      Number: (name, props) => @_paramByType 'Number', name, props
      CommaDelimitedList: (name, props) => @_paramByType 'CommaDelimitedList', name, props
    @_buildCall null, null, 'AWS', @AWS

  _paramByType: (type, name, props) =>
    result = {}
    result[name] = props
    props.Type = type
    @_set result, @_parameters
    @Params[name] = Ref: name

  _buildCall: (parent, lastKey, awsType, leaf) =>
    if leaf is null
      parent[lastKey] = (name, props) =>
        @_resourceByType awsType, name, props
    else
      for key, val of leaf
        @_buildCall leaf, key, "#{awsType}::#{key}", val

  _resourceByType: (type, name, props) =>
    result = {}
    result[name] =
      Type: type
      Properties: props
    @_set result, @_resources
    @Resources[name] = Ref: name

  _set: (source, target) ->
    for key, val of source
      target[key] = val

  Output: (name, props) =>
    #todo: support description
    result = {}
    result[name] =
      Value: props
    @_set result, @_outputs

  Description: (d) => @_description = d

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
  console.log JSON.stringify template, null, 2
