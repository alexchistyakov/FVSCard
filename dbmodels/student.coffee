rand = require "generate-key"
module.exports = (db,models) ->
  users = db.define "student",
    pub_id:
      type: "text"
    nickname:
      type: "text"
      required: true
    lastname:
      type: "text"
      required: true
    firstname:
      type: "text"
      required: true
    year:
      type: "text"
      required: true
    house:
      type: "text"
      reqiured: true
    room:
      type: "integer"
      required: true
    card_id:
      type: "text"
      required: true
  ,
    timestamp: true
    hooks:
      beforeCreate: ->
        @pub_id = rand.generateKey Math.floor(Math.random() * 15) + 15
      beforeSave: ->
        @firstname = @firstname.capitalize()
        @nickname = @nickname.capitalize()
        @lastname  = @lastname.capitalize()
    validations:
      pub_id: db.enforce.unique()
