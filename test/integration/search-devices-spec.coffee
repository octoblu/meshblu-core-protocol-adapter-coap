_           = require 'lodash'
{request}   = require 'coap'
Server      = require '../../src/server'
async       = require 'async'
Redis       = require 'ioredis'
RedisNS     = require '@octoblu/redis-ns'
MeshbluCoap = require 'meshblu-coap'
UUID        = require 'uuid'
{ JobManagerResponder } = require 'meshblu-core-job-manager'

describe 'Search Devices', ->
  beforeEach (done) ->
    @port = 0xd00d
    queueId = UUID.v4()
    @requestQueueName = "test:request:queue:#{queueId}"
    @responseQueueName = "test:response:queue:#{queueId}"
    @sut = new Server {
      port: @port
      disableLogging: true
      jobTimeoutSeconds: 1
      jobLogSampleRate: 0
      maxConnections: 10
      redisUri: 'redis://localhost'
      cacheRedisUri: 'redis://localhost'
      firehoseRedisUri: 'redis://localhost'
      namespace:   'meshblu:server:coap:test'
      jobLogQueue: 'meshblu:job-log'
      jobLogRedisUri: 'redis://localhost:6379'
      @requestQueueName
      @responseQueueName
    }

    @sut.run done

  afterEach (done) ->
    @sut.stop => done()

  beforeEach ->
    client = new RedisNS 'meshblu:server:coap:test', new Redis 'localhost', dropBufferSupport: true
    queueClient = new RedisNS 'meshblu:server:coap:test', new Redis 'localhost', dropBufferSupport: true
    @jobManager = new JobManagerResponder {
      client
      queueClient
      jobTimeoutSeconds: 1
      queueTimeoutSeconds: 1
      jobLogSampleRate: 0
      @requestQueueName
      @responseQueueName
    }

  describe 'GET /devices?foo=bar', ->
    context 'when the request is successful', ->
      beforeEach ->
        @jobManager.do (@request, callback) =>
          response =
            metadata:
              code: 200
              responseId: @request.metadata.responseId
            data: [
              uuid: 'new-uuid'
              something: true
            ]

          callback null, response

      beforeEach (done) ->
        meshblu = new MeshbluCoap server: 'localhost', port: @port, uuid: 'some-uuid', token: 'some-token'
        meshblu.devices foo: 'bar', (error, @response) =>
          done error

      it 'should return a device', ->
        expect(@request.rawData).to.equal '{"foo":"bar"}'
        expect(@request.metadata.auth).to.deep.equal uuid: 'some-uuid', token: 'some-token'
        expect(@request.metadata.jobType).to.equal 'SearchDevices'
        expect(@response).to.deep.equal [uuid: 'new-uuid', something: true]
