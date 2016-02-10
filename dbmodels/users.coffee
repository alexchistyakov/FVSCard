crypto = require "crypto"
rand = require "generate-key"
module.exports = (db,models) ->
	users = db.define "users",
		pub_id:
			type: "text"
		username:
			type: "text"
			required: true
		password:
			type: "text"
			required: true
	,
		timestamp: true
		hooks:
			beforeCreate: ->
				@pub_id = rand.generateKey Math.floor(Math.random() * 15) + 15
				@password = @hash @password
		methods:
			hash: (data) ->
				crypto.createHash("md5").update(data).digest("hex")
		validations:
			pub_id: db.enforce.unique()
			username: db.enforce.unique()

	users.hash = (data) ->
		crypto.createHash("md5").update(data).digest("hex")

	users
