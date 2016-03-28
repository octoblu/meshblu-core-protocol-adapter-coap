_ = require 'lodash'
{request} = require 'coap'
Server = require '../../src/server'
async      = require 'async'
redis      = require 'ioredis'
RedisNS    = require '@octoblu/redis-ns'
JobManager = require 'meshblu-core-job-manager'
MeshbluCoap = require 'meshblu-coap'

describe 'Status', ->
  beforeEach (done) ->
    @port = 0xd00d
    @sut = new Server
      port: @port
      disableLogging: true
      jobTimeoutSeconds: 1
      jobLogSampleRate: 0
      namespace:   'meshblu:server:coap:test'
      jobLogQueue: 'meshblu:job-log'
      jobLogRedisUri: 'redis://localhost:6379'

    @sut.run done

  afterEach (done) ->
    @sut.stop => done()

  beforeEach ->
    @redis = new RedisNS 'meshblu:server:coap:test', redis.createClient()
    @jobManager = new JobManager client: @redis, timeoutSeconds: 1

  describe 'GET /status', ->
    context 'when the request is successful', ->
      beforeEach ->
        async.forever (next) =>
          @jobManager.getRequest ['request'], (error, request) =>
            next request
            return unless request?
            @request = request

            response =
              metadata:
                code: 204
                responseId: request.metadata.responseId
              rawData: '{"meshblu":"online"}'

            @jobManager.createResponse 'response', response, (error) =>
              throw error if error?

      beforeEach (done) ->
        meshblu = new MeshbluCoap server: 'localhost', port: @port
        meshblu.status (error, @response) =>
          done error

      it 'should return a 204', ->
        expect(@response).to.deep.equal meshblu: 'online'
        expect(@request.metadata.jobType).to.equal 'GetStatus'
