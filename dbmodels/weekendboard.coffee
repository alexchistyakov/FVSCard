rand = require "generate-key"
module.exports = (db,models) ->
  db.define "weekend_board",
    pub_id:
      type: "text"
    date_start:
      type: "date"
      required: true
    date_end:
      type: "date"
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
