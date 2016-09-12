rand = require "generate-key"
module.exports = (db,models) ->
  db.define "checkout",
    pub_id:
      type: "text"
    board_id:
      type: "text"
      required: true
    student_id:
      type: "text"
      required: true
    date_leave:
      type: "date"
      required: true
    date_return:
      type: "date"
    time_leave:
      type: "text"
      required: true
    time_return:
      type: "text"
      required: true
    location:
      type: "text"
      required: true
    transport:
      type: "text"
      required: true
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
