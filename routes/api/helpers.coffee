module.exports =

  findOneByPubId: (table, pub_id, models, callback) ->
    models[table].one
      pub_id: pub_id
    , (err, res) ->
      callback err,res

  findByPubId: (table, pub_id, models, callback) ->
    models[table].find
      pub_id: pub_id
    , (err, res) ->
      callback err,res

  checkExistsByPubId: (table, pub_id, models, callback) ->
    models[table].one
      pub_id: pub_id
    , (err, res) ->
      callback err,res

  verifyExists: (table, pub_id, should, models, callback, clientCallback) ->
    @checkExistsByPubId table, pub_id, models, (err, res) ->
      if err?
        callback false, err
      else if res is !should
        callback false, if should then "Not such item exists" else "Item already exists"
      else
        callback()

  getDBItem: (table, pub_id, models, clientCallback, callback) ->
    @findOneByPubId table, pub_id, models, (err, res) =>
      @respondErrorDuplicate err, res, true, callback, clientcallback

  findSession: (sessionId, models, callback) ->
    models.checkinSession.one
      pub_id: sessionId
    , (err, session) ->
      if not session? and err?
        callback err, null
      else
        callback null, session

  findStudent: (pub_id, models, callback) ->
    models.student.one
      pub_id: pub_id
    , (err, res) ->
      if not res? and err?
        callback err, null
      else
        callback null, res

  respondErrorDuplicate: (err, res, exist, clientCallback, callback) ->
    if err?
      clientCallback false, err
    else if res? is not exist
      clientCallback false, if exist then "Item not found" else "Entry is a duplicate"
    else
      callback res
