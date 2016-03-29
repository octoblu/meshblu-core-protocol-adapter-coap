class GetStatusHandler
  constructor: ({@jobManager})->

  do: (req, res) =>
    request =
      metadata:
        jobType: 'GetStatus'

    @jobManager.do 'request', 'response', request, (error, response) =>
      setTimeout =>
        res.end response.rawData
      , 200

module.exports = GetStatusHandler
