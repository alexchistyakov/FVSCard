module.exports =
  findSession: (sessionId, models, callback) ->
    req.models.checkinSession.one
      pub_id: sessionId
    , (err, session) ->
      if not session? and err?
        callback err, null
      else
        callback null, session
