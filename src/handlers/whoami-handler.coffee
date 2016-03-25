class WhoamiHandler
  constructor: ({@jobManager})->

  do: (req, res) =>
    request =
      metadata:
        jobType: 'GetDevice'
        auth: req.meshbluAuth
        toUuid: req.meshbluAuth.uuid

    @jobManager.do 'request', 'response', request, (error, response) =>
      res.end response.rawData

module.exports = WhoamiHandler
