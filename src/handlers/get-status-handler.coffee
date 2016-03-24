class GetStatusHandler
  constructor: ({@jobManager})->

  do: (req, res) =>
    request =
      metadata:
        jobType: 'GetStatus'

    @jobManager.do 'request', 'response', request, (error, response) =>
      data =
        online: response?.metadata?.code == 204
      res.end JSON.stringify data

module.exports = GetStatusHandler
