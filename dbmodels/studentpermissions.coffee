rand = require "generate-key"
module.exports = (db,models) ->
  db.define "student_permissions",
    pub_id:
      type: "text"
    student_id:
      type: "text"
      required: true
    ride_with:
      type: "text"
      required: true
    drive_students:
      type: "boolean"
      required: true
    towncar_cab:
      type: "boolean"
      required: true
    stay_with:
      type: "text"
      required: true
  ,
    timestamp: true
    hooks:
      beforeCreate: ->
        @pub_id = rand.generateKey Math.floor(Math.random() * 15) + 15
    validations:
      pub_id: db.enforce.unique()
