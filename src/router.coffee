UrlPattern = require 'url-pattern'
GetStatusHandler = require './handlers/get-status-handler'

class Router
  constructor: ({@jobManager}) ->
  route: (app) =>
    app.on 'request', @_doRoute
    statusHandler = new GetStatusHandler {@jobManager}

    @get '/status', statusHandler

  get: (pattern, target) =>
    @GET[pattern] = target

  _doRoute: (req, res) =>
    packet = req._packet
    @[packet.method.upcase()]

module.exports = Router
