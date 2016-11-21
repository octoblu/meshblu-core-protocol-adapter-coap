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
    @namespace = 'ns'
    @redisUri = 'redis://localhost'
    @sut = new Server {
      port: @port
      disableLogging: true
      jobTimeoutSeconds: 1
      jobLogSampleRate: 0
      maxConnections: 10
      redisUri: @redisUri
      cacheRedisUri: @redisUri
      firehoseRedisUri: @redisUri
      namespace: @namespace
      jobLogQueue: 'meshblu:job-log'
      jobLogRedisUri: @redisUri
      @requestQueueName
      @responseQueueName
    }

    @sut.run done

  afterEach (done) ->
    @sut.stop => done()

  beforeEach (done) ->
    @jobManager = new JobManagerResponder {
      @namespace
      @redisUri
      maxConnections: 1
      jobTimeoutSeconds: 1
      queueTimeoutSeconds: 1
      jobLogSampleRate: 0
      @requestQueueName
      @responseQueueName
    }
    @jobManager.start done

  afterEach (done) ->
    @jobManager.stop done

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
