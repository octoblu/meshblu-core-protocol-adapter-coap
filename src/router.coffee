GetStatusHandler = require './handlers/get-status-handler'
GenericRouter = require './generic-router'

class Router
  constructor: ({@jobManager}) ->
    @genericRouter = new GenericRouter
    @statusHandler = new GetStatusHandler {@jobManager}

  route: (app) =>
    @_setup app
    app.get '/status', @statusHandler

  _setup: (app) =>
    app.get = @genericRouter.get
    app.on 'request', (req, res) =>
      @genericRouter.route {method: 'GET', uri: 'http://something.com', req, res}

module.exports = Router
