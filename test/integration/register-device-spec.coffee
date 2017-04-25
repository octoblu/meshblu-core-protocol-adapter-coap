_           = require 'lodash'
{request}   = require 'coap'
Server      = require '../../src/server'
async       = require 'async'
Redis       = require 'ioredis'
RedisNS     = require '@octoblu/redis-ns'
MeshbluCoap = require 'meshblu-coap'
UUID        = require 'uuid'
{ JobManagerResponder } = require 'meshblu-core-job-manager'

describe 'Register', ->
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

  describe 'POST /devices', ->
    context 'when the request is successful', ->
      beforeEach ->
        @workerFunc.yields null,
          metadata:
            code: 201
          data:
            uuid: 'new-uuid'
            token: 'new-token'

      beforeEach (done) ->
        meshblu = new MeshbluCoap server: 'localhost', port: @port
        meshblu.register type: 'boo-yah', (error, @response) =>
          done error

      it 'should return a device', ->
        request = @workerFunc.firstCall.args[0]
        expect(JSON.parse request.rawData).to.deep.equal type: 'boo-yah'
        expect(@response).to.deep.equal uuid: 'new-uuid', token: 'new-token'
        expect(request.metadata.jobType).to.equal 'RegisterDevice'
