orm = require "orm"
config = require "../config"
async = require "async"
init = false
dbModels = null
module.exports.express = orm.express config.database,
	define: (db,models,callback) ->
		dbModels = models
		models.student = require("./student")(db,models)
		models.studentStatus = require("./studentstatus")(db,models)
		models.checkinSession = require("./checkinsession")(db,models)

		models.studentStatus.hasOne "student",models.student,
			reverse : "statuses"

		models.studentStatus.hasOne "checkin_session",models.checkinSession,
			reverse : "sessions"

		unless init
			async.series [
				(next) =>
					if config.database.reset
						db.drop next
					else
						next()
				(next) =>
					if config.database.reset or config.database.sync
						db.sync next
					else
						next()
			], (errors) =>
				init = true
				callback() if callback?
		else
			callback() if callback?
module.exports.model = (name) ->
	dbModels[name]
