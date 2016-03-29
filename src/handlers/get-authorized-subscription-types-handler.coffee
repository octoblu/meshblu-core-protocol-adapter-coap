_ = require 'lodash'
http = require 'http'

class GetAuthorizedSubscriptionTypesHandler
  constructor: ({@jobManager,@auth,@requestQueue,@responseQueue}) ->

  do: (data, callback) =>
    request =
      metadata:
        jobType: 'GetAuthorizedSubscriptionTypes'
        toUuid: data.uuid
        auth: @auth
      data: data

    @jobManager.do @requestQueue, @responseQueue, request, (error, response) =>
      return callback error if error?
      callback null, JSON.parse(response.rawData)

module.exports = GetAuthorizedSubscriptionTypesHandler
