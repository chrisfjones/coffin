module.exports.doesTemplateReferenceIAM = (compiledTemplate) ->
  template = JSON.parse compiledTemplate
  for key, resource of template.Resources
    return true if resource.Type.match 'AWS::IAM::.*'
  return false
