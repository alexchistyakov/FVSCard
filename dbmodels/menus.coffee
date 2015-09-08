module.exports = (db,models) ->
	db.define "checkin_session",
		pub_id:
			type: "text"
		date:
			type: "text"
      required: true
		open:
			type: "boolean"
      required: true
	,
		timestamp: true
