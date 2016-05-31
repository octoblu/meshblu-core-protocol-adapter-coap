_ = require 'lodash'
{request} = require 'coap'
Server = require '../../src/server'
async      = require 'async'
redis      = require 'ioredis'
RedisNS    = require '@octoblu/redis-ns'
JobManager = require 'meshblu-core-job-manager'
MeshbluCoap = require 'meshblu-coap'

describe 'Register', ->
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

  describe 'POST /devices', ->
    context 'when the request is successful', ->
      beforeEach ->
        async.forever (next) =>
          @jobManager.getRequest ['request'], (error, request) =>
            next request
            return unless request?
            @request = request

            response =
              metadata:
                code: 201
                responseId: request.metadata.responseId
              data:
                uuid: 'new-uuid'
                token: 'new-token'

            @jobManager.createResponse 'response', response, (error) =>
              throw error if error?

      beforeEach (done) ->
        meshblu = new MeshbluCoap server: 'localhost', port: @port
        meshblu.register type: 'boo-yah', (error, @response) =>
          done error

      it 'should return a device', ->
        expect(JSON.parse @request.rawData).to.deep.equal type: 'boo-yah'
        expect(@response).to.deep.equal uuid: 'new-uuid', token: 'new-token'
        expect(@request.metadata.jobType).to.equal 'RegisterDevice'
