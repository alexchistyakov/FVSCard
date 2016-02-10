passport = require "passport"
dbModels = require "../../dbmodels"

module.exports.login = (username,password,callback) ->
  dbModels.model("users").find
    username: username
    password: dbModels.model("users").hash(password)
  , (err,users) ->
    if err
      callback err, null
    if users[0]?
      callback null,users[0]
    else
      callback null,null,
        success: false
        message: "Invalid credentials"

module.exports.authenticateLogin = (req,res,next) ->
  passport.authenticate("local-login", (err,user,info)->
    if info?
      res.json info
    else if err?
      next err
    else
      req.logIn user, (err) ->
        unless err?
          res.json
            success: true
            redirect: "/checkin"
        else
          next err
  )(req,res,next)

module.exports.authenticateRegister = (req,res,next) ->
  passport.authenticate("local-register", (err,user,info)->
    if info?
      res.json info
    else if err?
      next err
    else
      req.logIn user, (err) ->
        unless err?
          res.json
            success: true
            redirect: "/"
        else
          next err
  )(req,res,next)

module.exports.register = (req,username,password,done) ->
  req.models.users.exists
    username: req.param "username"
  , (err,exists) ->
    if err or exists
      done null,null,
        success: false
        message: "Username already in use"
    else
      req.models.users.create
        username: $.trim req.param "username"
        password: $.trim req.param "password"
      , (err,user) ->
        unless err
          done null,user
        else
          done null,null,
            success: false
            message: err.message

module.exports.serialize = (user,done) ->
  done null,user.pub_id

module.exports.deserialize = (pub_id,done) ->
  dbModels.model("users").one
    pub_id: pub_id
  , (err,user) ->
    done err,user

module.exports.logout = (req,res,next) ->
  req.logout()
  res.redirect "/"
