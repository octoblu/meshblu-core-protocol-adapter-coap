_                     = require 'lodash'
coap                  = require 'coap'
colors                = require 'colors'
redis                 = require 'ioredis'
RedisNS               = require '@octoblu/redis-ns'
debug                 = require('debug')('meshblu-core-protocol-adapter-coap:server')
Router                = require './router'
RedisPooledJobManager = require 'meshblu-core-redis-pooled-job-manager'
PackageJSON           = require '../package.json'
MessengerFactory      = require './messenger-factory'
UuidAliasResolver     = require 'meshblu-uuid-alias-resolver'

class Server
  constructor: (options)->
    {@disableLogging, @port, @aliasServerUri} = options
    {@redisUri, @namespace, @jobTimeoutSeconds} = options
    {@maxConnections} = options
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

    app.on 'error', (error) =>
      console.error "Server error:", error.stack

    app._origSendError = app._sendError
    app._sendError = (payload, rsinfo, packet) =>
      console.error "Sending Client Error: #{payload.toString()}"
      process.exit 1

    jobManager = new RedisPooledJobManager {
      jobLogIndexPrefix: 'metric:meshblu-core-protocol-adapter-coap'
      jobLogType: 'meshblu-core-protocol-adapter-coap:request'
      @jobTimeoutSeconds
      @jobLogQueue
      @jobLogRedisUri
      @jobLogSampleRate
      @maxConnections
      @redisUri
      @namespace
    }

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

module.exports = Server
