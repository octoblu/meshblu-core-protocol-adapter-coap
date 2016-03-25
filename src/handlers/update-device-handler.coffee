class UpdateDeviceHandler
  constructor: ({@jobManager})->

  do: (req, res) =>
    request =
      metadata:
        jobType: 'UpdateDevice'
        auth: req.meshbluAuth
        toUuid: req.params.id
      rawData: req._packet.payload

    @jobManager.do 'request', 'response', request, (error, response) =>
      res.code = '2.04'
      res.end response.rawData

module.exports = UpdateDeviceHandler
