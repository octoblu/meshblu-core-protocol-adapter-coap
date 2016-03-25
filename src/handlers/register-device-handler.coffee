class RegisterDeviceHandler
  constructor: ({@jobManager})->

  do: (req, res) =>
    request =
      metadata:
        jobType: 'RegisterDevice'
      rawData: req._packet.payload

    @jobManager.do 'request', 'response', request, (error, response) =>
      res.statusCode = response.metadata.code
      res.end response.rawData

module.exports = RegisterDeviceHandler
