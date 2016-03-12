rand = require "generate-key"
module.exports = (db,models) ->
  db.define "student_status",
    pub_id:
      type: "text"
    student_id:
      type: "text"
      required: true
    checkin_id:
      type: "text"
      required: true
    state:
      type: "integer"
      required: true
    notes:
      type: "text"
  ,
    timestamp: true
    hooks:
      beforeCreate: ->
        @pub_id = rand.generateKey Math.floor(Math.random() * 15) + 15
    validations:
      pub_id: db.enforce.unique()
