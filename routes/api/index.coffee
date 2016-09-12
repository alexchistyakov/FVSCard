commands = require "./commands"
adminCommands = require "./admincommands"
module.exports.express = (req, res, next) ->
  command = commands[req.param "command"]
  adminCommand = adminCommands[req.param "command"]
  if command?
    if req.isAuthenticated()
      command req, (success,data)->
        res.json
          success: success
          data: data
    else
      res.json
        success: false
        data:
          message: "Access Denied"
  else if adminCommand?
    if req.user.admin
      adminCommand req, (success,data)->
        res.json
          success: success
          data: data
    else
      res.json
        success: false
        data:
          message: "Access Denied"
