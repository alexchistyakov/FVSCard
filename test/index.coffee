module.exports = (req,res,next) ->
  req.models.users.create
    username: "fvs"
    password: "danes"
  , (err,user) ->
    console.log err
