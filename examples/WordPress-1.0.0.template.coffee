# from https://s3.amazonaws.com/cloudformation-templates-us-east-1/WordPress-1.0.0.template
result = require('../lib/coffin') ->
  @Description '''
WordPress is web software you can use to create a beautiful website or blog. This template creates a scalable WordPress installation using an Auto Scaling group behind an Elastic Load Balancer along with an Amazon Relational Database Service database instance to store the content. **WARNING** This template creates one or more Amazon EC2 instances and an Amazon Relational Database Service database instance. You will be billed for the AWS resources used if you create a stack from this template.
'''
  #forward declaration, kinda cheesy for the moment
  @DeclareResource 'WebServerGroup'
  @DeclareResource 'ElasticLoadBalancer'
  @DeclareResource 'LaunchConfig'

  #vars
  maxPort = '65535'
  allZones = @GetAZs @Region
  loadBalancerDns = @GetAtt('ElasticLoadBalancer', 'DNSName') #todo: want -> @Resources.ElasticLoadBalancer.DNSName
  openPort = (port) ->
    FromPort: port
    CidrIp: '0.0.0.0/0'
    ToPort: port
    IpProtocol: 'tcp'

  #params
  @Param.String 'KeyName', 'Name of an existing EC2 KeyPair to enable SSH access into the WordPress web server'
  @Param.String 'WordPressDBName', 'The WordPress database name'
    Default: 'wordpress'
    MinLength: '1'
    MaxLength: '64'
    AllowedPattern: "[^\\x00\\\\/.]*[^\\x00\\\\/. ]"
  @Param.String 'WordPressUser', 'The WordPress database admin account username'
    Default: 'admin'
    NoEcho: 'true'
    MinLength: '1'
    MaxLength: '16'
    AllowedPattern : '[a-zA-Z][a-zA-Z0-9]*'
  @Param.String 'WordPressPwd', 'The WordPress database admin account password'
    Default: 'admin'
    NoEcho: 'true'
    MinLength: '1'
    MaxLength: '41'
    AllowedPattern : '[a-zA-Z0-9]*'
  @Param.Number 'GroupSize', 'The initial number of EC2 instances for the WordPress web server'
    Default: '1'
    MinValue: '0'
  @Param.String 'InstanceType', 'The type of EC2 instances used for the WordPress web server'
    Default: 'm1.small'
    AllowedPattern : '[a-zA-Z0-9\\.]+'
  @Param.String 'OperatorEmail', 'Email address to notify if there are any operational issues'
    Default: 'nobody@amazon.com'
  @Param.Number 'WordPressDBPort', 'TCP/IP port for the WordPress database'
    Default: '3306'
    MinValue: '1150'
    MaxValue: maxPort
  @Param.Number 'WebServerPort', 'TCP/IP port for the WordPress web server'
    Default: '8888'
    MinValue: '1'
    MaxValue: maxPort

  @Mapping 'AWSInstanceType2Arch',
    't1.micro'   :
      Arch: '64'
    'm1.small'   :
      Arch: '32'
    'm1.large'   :
      Arch: '64'
    'm1.xlarge'  :
      Arch: '64'
    'm2.xlarge'  :
      Arch: '64'
    'm2.2xlarge' :
      Arch: '64'
    'm2.4xlarge' :
      Arch: '64'
    'c1.medium'  :
      Arch: '32'
    'c1.xlarge'  :
      Arch: '64'
    'cc1.4xlarge':
      Arch: '64'
  @Mapping 'AWSRegionArch2AMI',
    'us-east-1':
      32: 'ami-f417e49d'
      64: 'ami-f617e49f'
    'us-west-1':
      32: 'ami-bdc797f8'
      64: 'ami-bfc797fa'
    'eu-west-1':
      32: 'ami-a1c2f6d5'
      64: 'ami-a3c2f6d7'
    'ap-southeast-1':
      32: 'ami-2cf28c7e'
      64: 'ami-2ef28c7c'
    'ap-northeast-1':
      32: 'ami-cc03a8cd'
      64: 'ami-d203a8d3'
  rdsMultiAz = RDSMultiAZ: 'true'
  @Mapping 'AWSRegionCapabilities',
    'us-east-1' : rdsMultiAz
    'us-west-1' : rdsMultiAz
    'eu-west-1' : rdsMultiAz
    'ap-southeast-1' : rdsMultiAz
    'ap-northeast-1' : rdsMultiAz

  #resources
  @AWS.SNS.Topic 'AlarmTopic',
    Subscription: [
      Endpoint: @Params.OperatorEmail,
      Protocol: 'email'
    ]
  @AWS.CloudWatch.Alarm 'CPUAlarmHigh',
    AlarmDescription: 'Alarm if CPU too high or metric disappears indicating instance is down'
    Threshold: '10'
    EvaluationPeriods: '1'
    Statistic: 'Average'
    Threshold: '10'
    Period: '60'
    AlarmActions: [ @Resources.AlarmTopic ]
    Namespace: 'AWS/EC2'
    InsufficientDataActions: [ @Resources.AlarmTopic ]
    Dimensions: [
      Name: 'AutoScalingGroupName'
      Value: @Resources.WebServerGroup
    ]
    ComparisonOperator: 'GreaterThanThreshold',
    MetricName: 'CPUUtilization'
  @AWS.CloudWatch.Alarm 'TooManyUnhealthyHostsAlarm',
    AlarmDescription: 'Alarm if there are too many unhealthy hosts.'
    EvaluationPeriods: '1'
    Statistic: 'Average'
    Threshold: '0'
    Period: '60'
    AlarmActions: [ @Resources.AlarmTopic ]
    Namespace: 'AWS/ELB'
    InsufficientDataActions: [ @Resources.AlarmTopic ]
    Dimensions: [ Name: 'LoadBalancerName', Value: @Resources.ElasticLoadBalancer ]
    ComparisonOperator: 'GreaterThanThreshold'
    MetricName: 'UnHealthyHostCount'
  @AWS.CloudWatch.Alarm 'RequestLatencyAlarmHigh',
    AlarmDescription: "Alarm if there aren't any requests coming through"
    EvaluationPeriods: '1'
    Statistic: 'Average'
    Threshold: '1'
    Period: '60'
    AlarmActions: [ @Resources.AlarmTopic ]
    Namespace: 'AWS/ELB'
    InsufficientDataActions: [ @Resources.AlarmTopic ]
    Dimensions: [ Name: 'LoadBalancerName', Value: @Resources.ElasticLoadBalancer ]
    ComparisonOperator: 'GreaterThanThreshold'
    MetricName: 'Latency'

  @AWS.ElasticLoadBalancing.LoadBalancer 'ElasticLoadBalancer',
    Listeners: [
      InstancePort: @Params.WebServerPort,
      PolicyNames: [ 'p1' ],
      Protocol: 'HTTP',
      LoadBalancerPort: '80'
    ]
    HealthCheck:
      HealthyThreshold: '2'
      Timeout: '5'
      Interval: '10'
      UnhealthyThreshold: '5'
      Target: @Join '', 'HTTP:', @Params.WebServerPort, '/wp-admin/install.php'
    AvailabilityZones: allZones
    LBCookieStickinessPolicy: [
      CookieExpirationPeriod: '30',
      PolicyName: 'p1'
    ]

  @AWS.EC2.SecurityGroup 'EC2SecurityGroup',
    GroupDescription: 'HTTP and SSH access'
    SecurityGroupIngress: [ openPort('22'), openPort(@Params.WebServerPort) ]
  @AWS.RDS.DBSecurityGroup 'DBSecurityGroup',
    GroupDescription: 'database access'
    DBSecurityGroupIngress:
      EC2SecurityGroupName: @Resources.EC2SecurityGroup

  @AWS.RDS.DBInstance 'WordPressDB',
    Engine: 'MySQL'
    DBName: @Params.WordPressDBName
    Port: @Params.WordPressDBPort
    MultiAZ : @FindInMap 'AWSRegionCapabilities', @Region, 'RDSMultiAZ'
    MasterUsername: @Params.WordPressUser
    DBInstanceClass: 'db.m1.small'
    DBSecurityGroups: [ @Resources.DBSecurityGroup ]
    AllocatedStorage: '5'
    MasterUserPassword: @Params.WordPressPwd
  @AWS.AutoScaling.AutoScalingGroup 'WebServerGroup',
    LoadBalancerNames: [ @Resources.ElasticLoadBalancer ]
    LaunchConfigurationName: @Resources.LaunchConfig
    AvailabilityZones: allZones
    MinSize: '0'
    MaxSize: '3'
    DesiredCapacity: '1'
    NotificationConfiguration:
      TopicARN: @Resources.AlarmTopic
      NotificationTypes: [
       'autoscaling:EC2_INSTANCE_LAUNCH',
       'autoscaling:EC2_INSTANCE_LAUNCH_ERROR',
       'autoscaling:EC2_INSTANCE_TERMINATE',
       'autoscaling:EC2_INSTANCE_TERMINATE_ERROR'
      ]
  @AWS.AutoScaling.LaunchConfiguration 'LaunchConfig',
    SecurityGroups: [ @Resources.EC2SecurityGroup ]
    ImageId: @FindInMap 'AWSRegionArch2AMI', @Region, @FindInMap('AWSInstanceType2Arch', @Params.InstanceType, 'Arch')
    UserData:
      @Base64 @Join ':', @Params.WordPressDBName, @Params.WordPressUser, @Params.WordPressPwd, @Params.WordPressDBPort, @GetAtt('WordPressDB', 'Endpoint.Address'), @Params.WebServerPort, loadBalancerDns
    KeyName: @Params.KeyName
    InstanceType: @Params.InstanceType

  @Output 'InstallURL', 'Installation URL of the WordPress website',
    @Join '', 'http://', loadBalancerDns, '/wp-admin/install.php'
  @Output 'WebsiteURL',
    @Join '', 'http://', loadBalancerDns

module.exports = result
