rand = require "generate-key"
module.exports =
  WAIT_TIMEOUT: 5000
  PING_TIMEOUT: 5000
  openReaders: []
  boundReaders: []

  createConnection: (readerSocket)->
    id = rand.generateKey 4
    @openReaders.push
      id: id
      socket: readerSocket
    return id

  terminate: (id)->
    for i in [0...@boundReaders.length]
      reader = @boundReaders[i]
      if reader.id is id
        client = reader.user
        unless client.disconnected
          client.emit "reader disconnected",
            id: id
        @boundReaders.splice i, 1
        return
    for i in [0...@openReaders.length]
      reader = @openReaders[i]
      if reader.id is id
        @openReaders.splice i,1
        return

  findBoundById: (id) ->
    for reader in @boundReaders
      if reader.id is id
        return reader

  findOpenById: (id) ->
    for reader in @openReaders
      if reader.id is id
        return reader

  findReader: (id) ->
    reader = @findBoundById id
    unless reader?
      reader = @findOpenById id
    return reader

  findBoundByUser: (user) ->
    for reader in @boundReaders
      if reader.user is user
        return reader

  findBoundByReader: (socket) ->
    for reader in @boundReaders
      if reader.socket is socket
        return reader

  findOpenByReader: (socket) ->
    for reader in @openReaders
      if reader.socket is socket
        return socket

  update: (id, socket, data)->
    bond = @findBoundById id
    if bond?
      bond.user.send "reader update", data
    else
      throw new Error "Invalid Reader id"

  express: (req,res,next)=>
    req.cardReader =
      requestBind: @requestBind
    next()

  useIo: (io) ->
    @io = io

  useTcp: (tcp) ->
    @tcp = tcp

  useDB: (models) ->
    @models = models

  init: ->
    unless @io?
      throw new Error "Dude, I need a socket.io to work"
    @io.sockets.on "connection", (socket)=>
      socket.on "disconnect", =>
        reader = @findBoundByUser socket
        if reader?
          @terminate reader.id
      socket.on "request bind", (data)=>
        @requestBind socket, data.key, @respondBind
      socket.on "break bind", =>
        reaader = @findBoundByUser socket
        if reader?
          @terminate reader.id
    @tcp.on "connection", (socket)=>
      key = @createConnection socket
      socket.on "data", (data)=>
        @clearTimeouts key
        unless data.ping?
          @[data.action] data.data.key, socket, data.data
        @resetTrackAlive key
      socket.on "end", =>
        @clearTimeouts key
        @terminate key
      socket.write key
      @resetTrackAlive key

  resetTrackAlive: (id) ->
    reader = @findReader id
    if not reader.waitTimeout? and not reader.pingTimeout?
      reader.waitTimeout = setTimeout =>
        reader.pingTimeout = setTimeout =>
          @clearTimeouts id
          @terminate id
          reader.socket.end()
        , @PING_TIMEOUT
        reader.socket.write
          ping: "ping"
      , @WAIT_TIMEOUT

  clearTimeouts: (id) ->
    reader = @findReader id
    if reader?
      clearTimeout reader.waitTimeout
      clearTimeout reader.pingTimeout
      reader.waitTimeout = null
      reader.pingTimeout = null

  requestBind: (user, id, callback) ->
    reader = @findOpenById id
    if reader?
      @clearTimeouts id
      @openReaders.splice i, 1
      @boundReaders.push
        id: id
        user: user
        socket: reader.socket
      reader.socket.write
        bound: true
      callback user,true,
        id: id
      @resetTrackAlive id
    else
      callback user,false, "Reader not found"

  respondBind: (user, success, data) =>
    user.emit "reader bind",
      success: success
      data: data

  cardSwipe: (key, socket, data) ->
    bound = @findBoundByReader socket
    unless bound?
      socket.write
        success: false
        message: "Reader not bound to client"
      return

    socket.write
      success: true

    @models.model("student").one
      card_id: data.card_id
    , (err, res) ->
      console.log data.card_id
      success = false
      data = {}
      if err?
        data =
          message: "Database error"
          error: null
      else if not res?
        data =
          message: "Student not found"
          error: null
      else
        success = true
        data =
          student: res
      bound.user.emit "card swipe",
        success: success
        data: data
