resources = {}
params = {}
outputs = {}

coffeecloud = {}
coffeecloud.run = (func) ->
  context = {}
  context.Param = context.Params = (param) ->
    #todo: validate param structure
    for key, val of param
      params[key] = val
  func.apply context, [context]
  template =
    AWSTemplateFormatVersion: '2010-09-09'
    Description:              'Dynamic stack test'
    Parameters:               params
    Resources:                resources
    Outputs:                  outputs

  console.log template

exports = module.exports = coffeecloud.run
