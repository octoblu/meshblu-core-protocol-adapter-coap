class SearchDevicesHandler
  constructor: ({@jobManager})->

  do: (req, res) =>
    request =
      metadata:
        jobType: 'SearchDevices'
        auth: req.meshbluAuth
        toUuid: req.params.id
      data: req.query

    @jobManager.do request, (error, response) =>
      res.end response.rawData

module.exports = SearchDevicesHandler
