rand = require "generate-key"
module.exports = (db,models) ->
  db.define "parietal",
    pub_id:
      type: "text"
    board_id:
      type: "text"
      required: true
    time_start:
      type: "text"
      required: true
    time_end:
      type: "text"
    date:
      type: "date"
      required: true
    visitor_id:
      type: "text"
      required: true
    host_id:
      type: "text"
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
