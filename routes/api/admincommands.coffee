helpers = require "./helpers"
module.exports =
  "create-student": (req, callback) ->
    req.models.student.create
      firstname: req.param "firstname"
      lastname: req.param "lastname"
      nickname: req.param("nickname") ? req.param "firstname"
      house: req.param("dorm") ? "DAY"
      room: req.param("room") ? null
      year: req.param("year")
      card_id: req.param("card_id")
      phone_number: req.param("phone_number")
    , (err, res) ->
      if err?
        callback false, err
      else
        callback true, null

  "delete-student": (req, callback) ->
    req.models.student.one
      pub_id: req.param "pub_id"
    , (err, res) ->
      if err?
        callback false, err
      else if not res?
        callback false, "Student not found"
      else
        res.remove (err) ->
          callback err?, err

  "modify-student": (req, callback) ->

  "add-student-permissions": (req, callback) ->
  "modify-student-permissions": (req, callback) ->
