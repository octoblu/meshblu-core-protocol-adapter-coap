_                 = require 'lodash'
coap              = require 'coap'
colors            = require 'colors'
redis             = require 'ioredis'
RedisNS           = require '@octoblu/redis-ns'
debug             = require('debug')('meshblu-core-protocol-adapter-coap:server')
Router            = require './router'
{Pool}            = require 'generic-pool'
PooledJobManager  = require 'meshblu-core-pooled-job-manager'
JobLogger         = require 'job-logger'
PackageJSON       = require '../package.json'
MessengerFactory  = require './messenger-factory'
UuidAliasResolver = require 'meshblu-uuid-alias-resolver'

class Server
  constructor: (options)->
    {@disableLogging, @port, @aliasServerUri} = options
    {@redisUri, @namespace, @jobTimeoutSeconds} = options
    {@connectionPoolMaxConnections} = options
    {@jobLogRedisUri, @jobLogQueue, @jobLogSampleRate} = options
    @panic 'missing @jobLogQueue', 2 unless @jobLogQueue?
    @panic 'missing @jobLogRedisUri', 2 unless @jobLogRedisUri?
    @panic 'missing @jobLogSampleRate', 2 unless @jobLogSampleRate?

  address: =>
    port: @server._port
    address: @server._address

  panic: (message, exitCode, error) =>
    error ?= new Error('generic error')
    console.error colors.red message
    console.error error?.stack
    process.exit exitCode

  run: (callback) =>
    app = coap.createServer()

    app._origSendError = app._sendError
    app._sendError = (payload, rsinfo, packet) =>
      console.error "Error: #{payload.toString()}"
      # app._origSendError payload, rsinfo, packet

    jobLogger = new JobLogger
      jobLogQueue: @jobLogQueue
      sampleRate: @jobLogSampleRate
      indexPrefix: 'metric:meshblu-core-protocol-adapter-coap'
      type: 'meshblu-core-protocol-adapter-coap:request'
      client: redis.createClient(@jobLogRedisUri)

    connectionPool = @_createConnectionPool(maxConnections: @connectionPoolMaxConnections)

    jobManager = new PooledJobManager
      timeoutSeconds: @jobTimeoutSeconds
      pool: connectionPool
      jobLogger: jobLogger

    uuidAliasClient = _.bindAll new RedisNS 'uuid-alias', redis.createClient(@redisUri)
    uuidAliasResolver = new UuidAliasResolver
      cache: uuidAliasResolver
      aliasServerUri: @aliasServerUri

    messengerFactory = new MessengerFactory {uuidAliasResolver, @redisUri, @namespace}

    router = new Router {jobManager, app, messengerFactory}
    app.on 'request', router.route

    @server = app.listen @port, callback

  stop: (callback) =>
    @server.close callback

  _createConnectionPool: ({maxConnections}) =>
    connectionPool = new Pool
      max: maxConnections
      min: 0
      returnToHead: true # sets connection pool to stack instead of queue behavior
      create: (callback) =>
        client = new RedisNS @namespace, redis.createClient(@redisUri)

        client.on 'end', ->
          client.hasError = new Error 'ended'

        client.on 'error', (error) ->
          client.hasError = error
          callback error if callback?

        client.once 'ready', ->
          callback null, client
          callback = null

      destroy: (client) => client.end true
      validate: (client) => !client.hasError?

    return connectionPool

module.exports = Server
