class GetDevicePublicKeyHandler
  constructor: ({@jobManager})->

  do: (req, res) =>
    request =
      metadata:
        jobType: 'GetDevicePublicKey'
        toUuid: req.params.id

    @jobManager.do 'request', 'response', request, (error, response) =>
      res.end response.rawData

module.exports = GetDevicePublicKeyHandler
