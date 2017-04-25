_           = require 'lodash'
{request}   = require 'coap'
Server      = require '../../src/server'
async       = require 'async'
Redis       = require 'ioredis'
RedisNS     = require '@octoblu/redis-ns'
MeshbluCoap = require 'meshblu-coap'
UUID        = require 'uuid'
{ JobManagerResponder } = require 'meshblu-core-job-manager'

describe 'Subscribe', ->
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
    @workerFunc = sinon.stub()

    @jobManager = new JobManagerResponder {
      @namespace
      @redisUri
      maxConnections: 1
      jobTimeoutSeconds: 1
      queueTimeoutSeconds: 1
      jobLogSampleRate: 0
      @requestQueueName
      @responseQueueName
      @workerFunc
    }
    @jobManager.start done

  afterEach (done) ->
    @jobManager.stop done

  describe 'GET /subscribe', ->
    context 'when the request is successful', ->
      beforeEach ->
        @workerFunc.yields null,
          metadata:
            code: 200
          data:
            types: ['broadcast']

      beforeEach (done) ->
        meshblu = new MeshbluCoap server: 'localhost', port: @port, uuid: 'some-uuid', token: 'some-token'
        meshblu.subscribe 'new-uuid', {}, (error, @response) =>
          done error

      it 'should return a device', ->
        request = @workerFunc.firstCall.args[0]
        expect(request.metadata.toUuid).to.equal 'new-uuid'
        expect(request.metadata.jobType).to.equal 'GetAuthorizedSubscriptionTypes'
