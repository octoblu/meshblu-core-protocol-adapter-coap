class SendMessageHandler
  constructor: ({@jobManager})->

  do: (req, res) =>
    request =
      metadata:
        jobType: 'SendMessage'
        auth: req.meshbluAuth
      rawData: req._packet.payload

    @jobManager.do 'request', 'response', request, (error, response) =>
      res.statusCode = 201
      res.end response.rawData

module.exports = SendMessageHandler
