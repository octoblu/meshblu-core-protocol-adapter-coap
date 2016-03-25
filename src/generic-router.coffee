_ = require 'lodash'
UrlPattern = require 'url-pattern'
debug = require('debug')('generic-router')
qs = require 'qs'

class GenericRouter
  @CODE_METHOD_MAP =
    '0.01' : 'GET'
    '0.02' : 'POST'
    '0.03' : 'PUT'
    '0.04' : 'DELETE'

  constructor: ->
    @GET = []
    @POST = []
    @PUT = []
    @DELETE = []

  get: (uri, target) =>
    pattern = new UrlPattern uri
    @GET.push {target, pattern, uri}

  post: (uri, target) =>
    pattern = new UrlPattern uri
    @POST.push {target, pattern, uri}

  put: (uri, target) =>
    pattern = new UrlPattern uri
    @PUT.push {target, pattern, uri}

  delete: (uri, target) =>
    pattern = new UrlPattern uri
    @DELETE.push {target, pattern, uri}

  route: ({req, res, code, uri}) =>
    [baseUri, queryStr] = uri.split /\?/
    req.query = qs.parse queryStr
    methodName = GenericRouter.CODE_METHOD_MAP[code]
    method = @[methodName]
    matcher = _.find method, ({pattern}) =>
      debug {matchedUri, baseUri}
      matches = pattern.match baseUri
      return unless matches?
      matchedUri = pattern.stringify matches
      return false if matchedUri != baseUri
      req.params = matches
      return true

    debug {code, methodName, matches: matcher?.uri}

    unless matcher?
      res.code = '4.04'
      res.end()
      return

    {target} = matcher

    unless target?
      res.code = '5.00'
      res.end()
      return

    target.do req, res

module.exports = GenericRouter
