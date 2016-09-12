rand = require "generate-key"
module.exports = (db,models) ->
  db.define "checkin_session",
    pub_id:
      type: "text"
    board_id:
      type: "text"
      required: true
    date:
      type: "date"
      required: true
    type:
      type: "text"
      required: true
    dorm:
      type: "text"
    open:
      type: "boolean"
  ,
    timestamp: true
    hooks:
      beforeCreate: ->
        @pub_id = rand.generateKey Math.floor(Math.random() * 15) + 15
    validations:
      pub_id: db.enforce.unique()
