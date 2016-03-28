class GetStatusHandler
  constructor: ({@jobManager})->

  do: (req, res) =>
    request =
      metadata:
        jobType: 'GetStatus'

    @jobManager.do 'request', 'response', request, (error, response) =>
      res.end response.rawData

module.exports = GetStatusHandler
