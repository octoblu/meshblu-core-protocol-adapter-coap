class UpdateDeviceHandler
  constructor: ({@jobManager})->

  do: (req, res) =>
    data = JSON.parse req._packet.payload
    request =
      metadata:
        jobType: 'UpdateDevice'
        auth: req.meshbluAuth
        toUuid: req.params.id
      data: $set: data

    @jobManager.do 'request', 'response', request, (error, response) =>
      res.code = '2.04'
      res.end response.rawData

module.exports = UpdateDeviceHandler
