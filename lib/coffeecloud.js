(function() {
  var CloudFormationTemplateContext;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __slice = Array.prototype.slice;

  CloudFormationTemplateContext = (function() {

    function CloudFormationTemplateContext() {
      this.Description = __bind(this.Description, this);
      this.Output = __bind(this.Output, this);
      this.Mapping = __bind(this.Mapping, this);
      this._resourceByType = __bind(this._resourceByType, this);
      this.DeclareResource = __bind(this.DeclareResource, this);
      this._buildCall = __bind(this._buildCall, this);
      this._paramByType = __bind(this._paramByType, this);
      var _this = this;
      this._resources = {};
      this._parameters = {};
      this._mappings = null;
      this._outputs = {};
      this._description = null;
      this.Params = {};
      this.Resources = {};
      this.Mappings = {};
      this.AWS = {
        AutoScaling: {
          AutoScalingGroup: null,
          LaunchConfiguration: null,
          ScalingPolicy: null,
          Trigger: null
        },
        CloudFormation: {
          Stack: null,
          WaitCondition: null,
          WaitConditionHandle: null
        },
        CloudFront: {
          Distribution: null
        },
        CloudWatch: {
          Alarm: null
        },
        EC2: {
          EIP: null,
          EIPAssociation: null,
          Instance: null,
          SecurityGroup: null,
          SecurityGroupIngress: null,
          Volume: null,
          VolumeAttachment: null
        },
        ElasticBeanstalk: {
          Application: null,
          Environment: null
        },
        ElasticLoadBalancing: {
          LoadBalancer: null
        },
        IAM: {
          AccessKey: null,
          Group: null,
          Policy: null,
          User: null,
          UserToGroupAddition: null
        },
        RDS: {
          DBInstance: null,
          DBSecurityGroup: null
        },
        Route53: {
          RecordSet: null,
          RecordSetGroup: null
        },
        S3: {
          Bucket: null,
          BucketPolicy: null
        },
        SNS: {
          Topic: null,
          TopicPolicy: null
        },
        SQS: {
          Queue: null,
          QueuePolicy: null
        }
      };
      this.Param = {
        String: function(name, arg1, arg2) {
          return _this._paramByType('String', name, arg1, arg2);
        },
        Number: function(name, arg1, arg2) {
          return _this._paramByType('Number', name, arg1, arg2);
        },
        CommaDelimitedList: function(name, arg1, arg2) {
          return _this._paramByType('CommaDelimitedList', name, arg1, arg2);
        }
      };
      this._buildCall(null, null, 'AWS', this.AWS);
    }

    CloudFormationTemplateContext.prototype._paramByType = function(type, name, arg1, arg2) {
      var result;
      result = {};
      if (!(arg1 != null)) {
        result[name] = {};
      } else if (!(arg2 != null)) {
        result[name] = typeof arg1 === 'string' ? {
          Description: arg1
        } : arg1;
      } else {
        result[name] = arg2;
        result[name].Description = arg1;
      }
      result[name].Type = type;
      this._set(result, this._parameters);
      return this.Params[name] = {
        Ref: name
      };
    };

    CloudFormationTemplateContext.prototype._buildCall = function(parent, lastKey, awsType, leaf) {
      var key, val;
      var _this = this;
      if (leaf != null) {
        for (key in leaf) {
          val = leaf[key];
          this._buildCall(leaf, key, "" + awsType + "::" + key, val);
        }
        return;
      }
      return parent[lastKey] = function(name, props) {
        return _this._resourceByType(awsType, name, props);
      };
    };

    CloudFormationTemplateContext.prototype.DeclareResource = function(name) {
      var _base, _ref;
      return (_ref = (_base = this.Resources)[name]) != null ? _ref : _base[name] = {
        Ref: name
      };
    };

    CloudFormationTemplateContext.prototype._resourceByType = function(type, name, props) {
      var result;
      result = {};
      result[name] = {
        Type: type,
        Properties: props
      };
      this._set(result, this._resources);
      return this.DeclareResource(name);
    };

    CloudFormationTemplateContext.prototype._set = function(source, target) {
      var key, val, _results;
      _results = [];
      for (key in source) {
        val = source[key];
        _results.push(target[key] = val);
      }
      return _results;
    };

    CloudFormationTemplateContext.prototype.Mapping = function(name, map) {
      var result, _ref;
      if ((_ref = this._mappings) == null) this._mappings = {};
      result = {};
      result[name] = map;
      return this._set(result, this._mappings);
    };

    CloudFormationTemplateContext.prototype.Output = function() {
      var args, name, result;
      name = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      result = {};
      if (args.length === 1) {
        result[name] = {
          Value: args[0]
        };
      }
      if (args.length === 2) {
        result[name] = {
          Description: args[0],
          Value: args[1]
        };
      }
      return this._set(result, this._outputs);
    };

    CloudFormationTemplateContext.prototype.Description = function(d) {
      return this._description = d;
    };

    CloudFormationTemplateContext.prototype.Tag = function(key, val) {
      return {
        Key: key,
        Value: val
      };
    };

    CloudFormationTemplateContext.prototype.Join = function() {
      var args, delimiter;
      delimiter = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      if (args.length === 1 && (args[0] instanceof Array)) {
        return {
          'Fn::Join': [delimiter, args[0]]
        };
      } else {
        return {
          'Fn::Join': [delimiter, args]
        };
      }
    };

    CloudFormationTemplateContext.prototype.FindInMap = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return {
        'Fn::FindInMap': args
      };
    };

    CloudFormationTemplateContext.prototype.GetAtt = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return {
        'Fn::GetAtt': args
      };
    };

    CloudFormationTemplateContext.prototype.Base64 = function(arg) {
      return {
        'Fn::Base64': arg
      };
    };

    CloudFormationTemplateContext.prototype.GetAZs = function(arg) {
      return {
        'Fn::GetAZs': arg
      };
    };

    CloudFormationTemplateContext.prototype.Region = 'AWS::Region';

    CloudFormationTemplateContext.prototype.StackName = 'AWS::StackName';

    return CloudFormationTemplateContext;

  })();

  module.exports.CloudFormationTemplateContext = CloudFormationTemplateContext;

  module.exports = function(func) {
    var context, template;
    context = new CloudFormationTemplateContext;
    func.apply(context, [context]);
    template = {
      AWSTemplateFormatVersion: '2010-09-09'
    };
    if (context._description != null) template.Description = context._description;
    template.Parameters = context._parameters;
    if (context._mappings != null) template.Mappings = context._mappings;
    template.Resources = context._resources;
    template.Outputs = context._outputs;
    return template;
  };

}).call(this);
