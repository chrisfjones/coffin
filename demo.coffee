compiledJsonTemplateAsAnObject = require('coffin') ->
  @Description 'embedded coffin'
  @Param.String 'name'
  @AWS.EC2.Instance
    ImageId: 'you get the idea...'
