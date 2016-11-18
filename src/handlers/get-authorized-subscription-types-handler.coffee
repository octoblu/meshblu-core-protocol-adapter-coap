_ = require 'lodash'
http = require 'http'

class GetAuthorizedSubscriptionTypesHandler
  constructor: ({@jobManager,@auth}) ->

  do: (data, callback) =>
    request =
      metadata:
        jobType: 'GetAuthorizedSubscriptionTypes'
        toUuid: data.uuid
        auth: @auth
      data: data

    @jobManager.do request, (error, response) =>
      return callback error if error?
      callback null, JSON.parse(response.rawData)

module.exports = GetAuthorizedSubscriptionTypesHandler
