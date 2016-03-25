class MyDevicesHandler
  constructor: ({@jobManager})->

  do: (req, res) =>
    request =
      metadata:
        jobType: 'SearchDevices'
        auth: req.meshbluAuth
      data:
        owner: req.meshbluAuth.uuid

    @jobManager.do 'request', 'response', request, (error, response) =>
      res.end response.rawData

module.exports = MyDevicesHandler
