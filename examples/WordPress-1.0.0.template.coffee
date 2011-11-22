require('../lib/coffeecloud') ->
  @Params
    KeyName:
      Description: 'Name of an existing EC2 KeyPair to enable SSH access into the WordPress web server'
      Type: 'String'
    WordPressDBName:
      Default: 'wordpress',
      Description: 'The WordPress database name',
      Type: 'String',
      MinLength: '1',
      MaxLength: '64',
      AllowedPattern: '[^\x00\\/.]*[^\x00\\/. ]'
