_                       = require 'lodash'
coap                    = require 'coap'
colors                  = require 'colors'
Redis                   = require 'ioredis'
RedisNS                 = require '@octoblu/redis-ns'
debug                   = require('debug')('meshblu-core-protocol-adapter-coap:server')
Router                  = require './router'
PackageJSON             = require '../package.json'
MessengerManagerFactory = require 'meshblu-core-manager-messenger/factory'
UuidAliasResolver       = require 'meshblu-uuid-alias-resolver'
JobLogger               = require 'job-logger'
{ JobManagerRequester } = require 'meshblu-core-job-manager'

class Server
  constructor: (options)->
    {
      @disableLogging
      @port
      @aliasServerUri
      @redisUri
      @cacheRedisUri
      @firehoseRedisUri
      @namespace
      @jobTimeoutSeconds
      @maxConnections
      @jobLogRedisUri
      @jobLogQueue
      @jobLogSampleRate
      @requestQueueName
      @responseQueueName
    } = options
    @panic 'missing @redisUri', 2 unless @redisUri?
    @panic 'missing @cacheRedisUri', 2 unless @cacheRedisUri?
    @panic 'missing @firehoseRedisUri', 2 unless @firehoseRedisUri?
    @panic 'missing @jobLogQueue', 2 unless @jobLogQueue?
    @panic 'missing @jobLogRedisUri', 2 unless @jobLogRedisUri?
    @panic 'missing @jobLogSampleRate', 2 unless @jobLogSampleRate?
    @panic 'missing @requestQueueName', 2 unless @requestQueueName?
    @panic 'missing @responseQueueName', 2 unless @responseQueueName?

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

    app.on 'error', (error) =>
      console.error "Server error:", error.stack

    app._origSendError = app._sendError
    app._sendError = (payload, rsinfo, packet) =>
      console.error "Sending Client Error: #{payload.toString()}"
      process.exit 1

    client = new RedisNS @namespace, new Redis @redisUri, dropBufferSupport: true
    queueClient = new RedisNS @namespace, new Redis @redisUri, dropBufferSupport: true

    jobLogger = new JobLogger
      client: new Redis @jobLogRedisUri, dropBufferSupport: true
      indexPrefix: 'metric:meshblu-core-protocol-adapter-mqtt'
      type: 'meshblu-core-protocol-adapter-mqtt:request'
      jobLogQueue: @jobLogQueue

    @jobManager = new JobManagerRequester {
      client
      queueClient
      @jobTimeoutSeconds
      @jobLogSampleRate
      @requestQueueName
      @responseQueueName
      queueTimeoutSeconds: @jobTimeoutSeconds
    }

    @jobManager._do = @jobManager.do
    @jobManager.do = (request, callback) =>
      @jobManager._do request, (error, response) =>
        jobLogger.log { error, request, response }, (jobLoggerError) =>
          return callback jobLoggerError if jobLoggerError?
          callback error, response

    queueClient.on 'ready', =>
      @jobManager.startProcessing()

    uuidAliasClient = _.bindAll new RedisNS 'uuid-alias', new Redis @cacheRedisUri, dropBufferSupport: true
    uuidAliasResolver = new UuidAliasResolver
      cache: uuidAliasResolver
      aliasServerUri: @aliasServerUri

    messengerManagerFactory = new MessengerManagerFactory {uuidAliasResolver, @namespace, redisUri: @firehoseRedisUri}

    router = new Router {@jobManager, app, messengerManagerFactory}
    app.on 'request', router.route

    @server = app.listen @port, callback

  stop: (callback) =>
    @jobManager?.stopProcessing()
    @server.close callback

module.exports = Server
