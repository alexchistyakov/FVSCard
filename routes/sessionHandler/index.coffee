module.exports.showSessionPage = (req,res,next) ->
  if req.isAuthenticated()
    res.render "checkin",
      title: "Checkin"
      js: req.coffee.renderTags "checkin"
      css: req.css.renderTags "checkin"
  else
    res.redirect "/login"
module.exports.verifyAuthAndRedirect = (req,res,next) ->
  if req.isAuthenticated()
    res.redirect "/checkin"
  else
    res.redirect "/login"
