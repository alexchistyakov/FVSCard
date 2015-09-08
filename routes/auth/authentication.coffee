passport = require "passport"
dbModels = require "../../models"

module.exports.login = (email,password,callback) ->
	dbModels.model("users").find
		email:email
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
						redirect: "/"
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

module.exports.register = (req,email,password,done) ->
	req.models.users.exists
		email: req.param "email"
	, (err,exists) ->
		if err or exists
			done null,null,
				success: false
				message: "Email already in use"
		else
			req.models.users.create
				username: $.trim req.param "username"
				email: $.trim req.param "email"
				password: $.trim req.param "password"
			, (err,user) ->
				unless err
					done null,user
				else
					if err.message is "not-unique"
						done null,null,
							success: false
							message: "Username already in use"
					else
						console.log err
						done null,null,
							success: false
							message: "Email is invalid"


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
