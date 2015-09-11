module.exports.inputSession = (req, res, next) ->
  res.render "index",
    title: false
    js: req.coffee.renderTags "inputsession"
    css: req.css.renderTags "inputsession"

module.exports.joinSession = (req, res, next) ->
  req.models.checkinSession.one
    pub_id: req.param "sessionId"
  , (err, session) ->
    if not session? and err?
      res.json
        success: false
        message: "Invalid session"
    else
      req.session.checkinSessionId   = session.pub_id
      req.session.checkinInitialized = true

      res.redirect "/checkin"
