_ = require 'lodash'
{request} = require 'coap'
Server = require '../../src/server'
async      = require 'async'
redis      = require 'ioredis'
RedisNS    = require '@octoblu/redis-ns'
JobManager = require 'meshblu-core-job-manager'
MeshbluCoap = require 'meshblu-coap'

describe 'Search Devices', ->
  beforeEach (done) ->
    @port = 0xd00d
    @sut = new Server
      port: @port
      disableLogging: true
      jobTimeoutSeconds: 1
      jobLogSampleRate: 0
      maxConnections: 10
      redisUri: 'redis://localhost'
      namespace:   'meshblu:server:coap:test'
      jobLogQueue: 'meshblu:job-log'
      jobLogRedisUri: 'redis://localhost:6379'

    @sut.run done

  afterEach (done) ->
    @sut.stop => done()

  beforeEach ->
    @redis = new RedisNS 'meshblu:server:coap:test', redis.createClient(dropBufferSupport: true)
    @jobManager = new JobManager client: @redis, timeoutSeconds: 1

  describe 'GET /devices?foo=bar', ->
    context 'when the request is successful', ->
      beforeEach ->
        async.forever (next) =>
          @jobManager.getRequest ['request'], (error, request) =>
            next request
            return unless request?
            @request = request

            response =
              metadata:
                code: 200
                responseId: request.metadata.responseId
              data: [
                uuid: 'new-uuid'
                something: true
              ]

            @jobManager.createResponse 'response', response, (error) =>
              throw error if error?

      beforeEach (done) ->
        meshblu = new MeshbluCoap server: 'localhost', port: @port, uuid: 'some-uuid', token: 'some-token'
        meshblu.devices foo: 'bar', (error, @response) =>
          done error

      it 'should return a device', ->
        expect(@request.rawData).to.equal '{"foo":"bar"}'
        expect(@request.metadata.auth).to.deep.equal uuid: 'some-uuid', token: 'some-token'
        expect(@request.metadata.jobType).to.equal 'SearchDevices'
        expect(@response).to.deep.equal [uuid: 'new-uuid', something: true]
