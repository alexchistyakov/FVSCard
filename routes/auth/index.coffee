module.exports.loginPage = (req,res,next) ->
  req.authStrategy = "local-login"
  res.render "login",
		title: "Login"
		js: req.coffee.renderTags "login"
		css: req.css.renderTags "login"
module.exports.registerPage = (req,res,next) ->
  req.authStrategy = "local-register"
  res.render "register",
		title: "Register"
		js: req.coffee.renderTags "login"
		css: req.css.renderTags "login"
