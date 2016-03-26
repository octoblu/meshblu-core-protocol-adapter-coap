class RegisterDeviceHandler
  constructor: ({@jobManager})->

  do: (req, res) =>
    request =
      metadata:
        jobType: 'RegisterDevice'
      rawData: req._packet.payload

    @jobManager.do 'request', 'response', request, (error, response) =>
      if error?
        res.statusCode = 500
        res.end()
        return

      if response.metadata.code != 201
        res.statusCode = response.metadata.code
        res.end()
        return

      res.statusCode = response.metadata.code
      res.end response.rawData

module.exports = RegisterDeviceHandler
