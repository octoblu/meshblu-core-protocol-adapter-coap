_                         = require 'lodash'
GetStatusHandler          = require './handlers/get-status-handler'
GetDeviceHandler          = require './handlers/get-device-handler'
GetDevicePublicKeyHandler = require './handlers/get-device-public-key-handler'
RegisterDeviceHandler     = require './handlers/register-device-handler'
UnregisterDeviceHandler   = require './handlers/unregister-device-handler'
UpdateDeviceHandler       = require './handlers/update-device-handler'
MyDevicesHandler          = require './handlers/my-devices-handler'
SearchDevicesHandler      = require './handlers/search-devices-handler'
SendMessageHandler        = require './handlers/send-message-handler'
WhoamiHandler             = require './handlers/whoami-handler'
GenericRouter             = require './generic-router'

class Router
  constructor: ({@jobManager, @app, messengerFactory}) ->
    @genericRouter = new GenericRouter
    @_setup()

    @statusHandler = new GetStatusHandler {@jobManager}
    @getDeviceHandler = new GetDeviceHandler {@jobManager}
    @searchDevicesHandler = new SearchDevicesHandler {@jobManager}
    @getDevicePublicKeyHandler = new GetDevicePublicKeyHandler {@jobManager}
    @sendMessageHandler = new SendMessageHandler {@jobManager}
    @registerDeviceHandler = new RegisterDeviceHandler {@jobManager}
    @unregisterDeviceHandler = new UnregisterDeviceHandler {@jobManager}
    @updateDeviceHandler = new UpdateDeviceHandler {@jobManager}
    @whoamiHandler = new WhoamiHandler {@jobManager}
    @myDevicesHandler = new MyDevicesHandler {@jobManager}

    @app.get '/devices', @searchDevicesHandler
    @app.get '/devices/:id', @getDeviceHandler
    @app.get '/devices/:id/publickey', @getDevicePublicKeyHandler
    @app.put '/devices/:id', @updateDeviceHandler
    @app.post '/devices', @registerDeviceHandler
    @app.delete '/devices/:id', @unregisterDeviceHandler
    @app.get '/healthcheck', do: @_onHealthcheck
    @app.post '/messages', @sendMessageHandler
    @app.get '/mydevices', @myDevicesHandler
    @app.get '/status', @statusHandler
    @app.get '/subscribe', do: @_onSubscribe
    @app.get '/whoami', @whoamiHandler

  route: (req, res) =>
    {_packet} = req
    {code,options} = _packet
    uri = req.url
    req.meshbluAuth = @_getMeshbluAuth req
    @genericRouter.route {code, uri, req, res}

  _setup: =>
    @app.get = @genericRouter.get
    @app.post = @genericRouter.post
    @app.put = @genericRouter.put
    @app.delete = @genericRouter.delete

  _getMeshbluAuth: (req) =>
    {options} = req._packet
    uuidOption = _.find options, name: '98'
    tokenOption = _.find options, name: '99'
    return auth =
      uuid: uuidOption?.value.toString()
      token: tokenOption?.value.toString()

  _onHealthcheck: (req, res) =>
    res.end JSON.stringify online: true

  _onSubscribe: (req, res) =>

module.exports = Router
