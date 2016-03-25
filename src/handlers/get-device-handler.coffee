class GetDeviceHandler
  constructor: ({@jobManager})->

  do: (req, res) =>
    request =
      metadata:
        jobType: 'GetDevice'
        auth: req.meshbluAuth
        toUuid: req.params.id

    @jobManager.do 'request', 'response', request, (error, response) =>
      res.end response.rawData

module.exports = GetDeviceHandler
