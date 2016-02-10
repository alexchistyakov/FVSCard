commands = require "./commands"
module.exports.express = (req, res, next) ->
  command = commands[req.param "command"]
  console.log req.user
  if command? and req.isAuthenticated()
    command req, (success,data)->
      res.json
        success: success
        data: data
