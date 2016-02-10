rand = require "generate-key"
module.exports = (db,models) ->
  db.define "checkin_session",
    pub_id:
      type: "text"
    student_id:
      type: "text"
      required: true
    date_leave:
      type: "date"
      required: true
    date_return:
      type: "date"
    type:
      type: "enum"
      values: ["DX","WX"]
      required: true
    open:
      type: "boolean"
  ,
    timestamp: true
    hooks:
      beforeCreate: ->
        @pub_id = rand.generateKey Math.floor(Math.random() * 15) + 15
    validations:
      pub_id: db.enforce.unique()
