class UnregisterDeviceHandler
  constructor: ({@jobManager})->

  do: (req, res) =>
    request =
      metadata:
        jobType: 'UnregisterDevice'
        auth: req.meshbluAuth
        toUuid: req.params.id

    @jobManager.do 'request', 'response', request, (error, response) =>
      if error?
        res.statusCode = 500
        res.end()
        return

      if response.metadata.code != 204
        res.statusCode = response.metadata.code
        res.end()
        return

      res.statusCode = 202
      res.end()

module.exports = UnregisterDeviceHandler
