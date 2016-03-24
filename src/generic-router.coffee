UrlPattern = require 'url-pattern'
class GenericRouter
  constructor: ->
    @GET = {}
    
  get: (pattern, target) =>
    @GET[pattern] = target

  route: ({req, res, method, uri}) =>
    console.log @[method.upcase()]

module.exports = GenericRouter
