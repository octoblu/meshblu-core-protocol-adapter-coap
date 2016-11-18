class WhoamiHandler
  constructor: ({@jobManager})->

  do: (req, res) =>
    request =
      metadata:
        jobType: 'GetDevice'
        auth: req.meshbluAuth
        toUuid: req.meshbluAuth.uuid

    @jobManager.do request, (error, response) =>
      if error?
        res.statusCode = 500
        res.end()
        return

      if response.metadata.code != 200
        res.statusCode = response.metadata.code
        res.end()
        return

      res.end response.rawData

module.exports = WhoamiHandler
