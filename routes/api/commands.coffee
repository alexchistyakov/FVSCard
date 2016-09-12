orm = require "orm"

fs = require "fs"
helpers = require "./helpers"
module.exports =
  "load-essentials": (req, callback) ->

    req.models.student.find
      firstName: orm.ne null
    , "lastName", (err, students) ->

      resStudents = []
      for student in students
        resStudents.push
          pub_id: student.pub_id
          firstName: student.firstname
          lastName: student.lastname
          nickname: student.nickname
          year: student.year
          dorm: student.house
          room: student.room
          card_id: student.card_id
          phone_number: student.phone_number

      resHTMLs = {}
      dir = "#{__dirname}/../../views/client"
      for file in fs.readdirSync dir
        path = "client/"+file.replace ".html", ""
        req.app.render path, {}, (error,content) =>
          resHTMLs[file.replace ".html", ""] = content

      res =
        ui: resHTMLs
        data:
          students: resStudents

      callback true, res

  "create-weekend-board": (req, callback) ->
    req.models.weekendBoard.exists
      date_start: new Date req.param "date"
    , (err, exists) ->
      if err?
        callback false, err
      else if exists
        callback false, "Weekend Board Already Exists"
      else
        date = new Date req.param "date"
        date_end = new Date date
        date_end.setDate date.getDate() + 2
        req.models.weekendBoard.create
          date_start: date
          date_end: date_end
          open: false
        , (err,res) ->
          if err?
            callback false, err
          else
            session =
              pub_id: res.pub_id
              date_start: res.date_start
              date_end: res.date_end
              open: res.open
            callback true, session

  "load-weekend-board": (req, callback) ->
    req.models.weekendBoard.one
      date_start: new Date req.param "date"
    , (err, res) ->
      if err?
        callback false, err
      else if not res?
        callback false, "Weekend Board does not exist"
      else
        board =
          pub_id: res.pub_id
          date_start: res.date_start
          date_end: res.date_end
          open: res.open
        callback true, board

  "load-parietals": (req, callback) ->
    req.models.parietal.find
      board_id: req.param "boardId"
    , (err, parietals) ->
      if err?
        callback false, err
      else
        resParietals = []
        for res in parietals
          resParietals.push
            board_id: res.board_id
            pub_id: res.pub_id
            host_id: res.host_id
            visitor_id: res.visitor_id
            time_start: res.time_start
            time_end: res.time_end
            date: res.date
            open: res.open
        callback true, resParietals

  "load-checkouts": (req, callback) ->
    req.models.checkout.find
      board_id: req.param "boardId"
    , (err, checkouts) ->
      if err?
        callback false, err
      else
        resCheckouts = []
        for checkout in checkouts
          item =
            pub_id: checkout.pub_id
            board_id: checkout.board_id
            date_leave: checkout.date_leave
            date_return: checkout.date_return
            time_leave: checkout.time_leave
            time_return: checkout.time_return
            location: checkout.location
            transport: checkout.transport
            student_id: checkout.student_id
            type: checkout.type
            open: checkout.open
          resCheckouts.push item
        callback true, resCheckouts

  "load-sessions-for-board": (req, callback) ->
    req.models.checkinSession.find
      board_id: req.param "boardId"
    , (err, res) ->
      if err?
        callback false, err
      else if not res?
        callback true, []
      else
        resSessions = []
        for session in res
          resSessions.push
            board_id: session.board_id
            date: session.date
            type: session.type
            pub_id: session.pub_id
            dorm: session.dorm
            open: session.open
        callback true, resSessions

  "load-session-data": (req, callback) ->
    req.models.checkinSession.one
      board_id: req.param "boardId"
      date: new Date( req.param("date")) if req.param("date")?
      type: req.param("type") if req.param("type")?
      pub_id: req.param("pub_id") if req.param("pub_id")?
      dorm: res.param("dorm") if req.param("dorm")
    , (err, res) ->
      if err?
        callback false, err
      else if not res?
        callback false, "Session Not Found"
      else
        session =
          pub_id: res.pub_id
          board_id: res.board_id
          date: res.date
          dorm: res.dorm
          type: res.type
          open: res.open
        req.models.studentStatus.find
          checkin_id: res.pub_id
        , (err, statuses) ->
          if err? and not statuses?
            callback false, err
          else
            resOut =
              session: session
              students: []
            for status in statuses
              resOut.students.push
                student_id: status.student_id
                status: status.state
            callback true, resOut

  "update-checkout-status": (req, callback) ->
    helpers.getDBItem "checkout", req.param("pub_id"), req.models, callback, (checkout) ->
      toChange = req.param("open") is "true"
      if toChange is checkout.open
        callback true, null
      else
        checkout.open = toChange
        checkout.save (err) ->
          if err?
            callback false, err
          else
            req.io.broadcast "checkout update", checkout
            callback true, null

  "remove-checkout": (req, callback) ->
    helpers.getDBItem "checkout", req.param("pub_id"), req.models, callback, (checkout) ->
      checkout.remove (err) ->
        if err?
          callback false, err
        else
          req.app.io.broadcast "checkout removed", checkout
          callback true, null

  "create-checkout": (req, callback) ->
    req.models.checkout.exists
      board_id: req.param "boardId"
      student_id: req.param "student_id"
      date_leave: new Date req.param "date_leave"
      time_leave: req.param "time_leave"
      type: req.param "type"
    , (err, exists) ->
      if err?
        callback false, err
      else if exists
        callback false, "Checkout Already Exists"
      else
        req.models.checkout.create
          board_id: req.param "boardId"
          date_leave: new Date req.param "date_leave"
          date_return: new Date req.param "date_return"
          time_leave: req.param "time_leave"
          time_return: req.param "time_leave"
          location: req.param "location"
          transport: req.param "transport"
          student_id: req.param "student_id"
          type: req.param "type"
          open: req.param "open"
        , (err, checkout) ->
          if err?
            callback false, err
          else
            req.app.io.broadcast "checkout added", checkout
            callback true, null
            req.models.studentStatus.find
              student_id: checkout.student_id
            , (err, statuses) ->
              for status in statuses
                req.models.checkinSession.one
                  pub_id: status.checkin_id
                , (err, session) ->
                  if session.open?
                    status.state = if checkout.type is "DX" then 2 else 3
                    status.save (err)->
                      req.app.io.broadcast "update student", status


  "update-parietal-status": (req, callback) ->
    helpers.getDBItem "parietal", req.param("pub_id"), req.models, callback, (parietal) ->
      toChange = req.param("open") is "true"
      if toChange is parietal.open
        callback true, null
      else
        unless toChange
          time = req.param "time_end"
          unless time?
            callback false, "Need an end time to close parietal"
            return
          parietal.time_end = time
        else
          parietal.time_end = null
        parietal.open = toChange
        parietal.save (err) ->
          if err?
            callback false, err
          else
            req.io.broadcast "parietal update", parietal
            callback true, null

  "remove-parietal": (req, callback) ->
    helpers.getDBItem "parietal", req.param("pub_id"), req.models, callback, (parietal) ->
      parietal.remove (err) ->
        if err?
          callback false, err
        else
          req.app.io.broadcast "parietal removed", parietal
          callback true, null


  "create-parietal": (req, callback) ->
    req.models.parietal.exists
      board_id: req.param "boardId"
      date: new Date req.param "date"
      visitor_id: req.param "guest"
      host_id: req.param "host"
      time_start: req.param "timeStart"
    , (err, exists) ->
      if err?
        callback false, err
      else if exists
        callback false, "Parietal Already Exists"
      else
        req.models.parietal.create
          board_id: req.param "boardId"
          date: new Date req.param "date"
          visitor_id: req.param "guest"
          host_id: req.param "host"
          time_start: req.param "timeStart"
          open: req.param "open"
        , (err, parietal) ->
          if err?
            callback false, err
          else
            res =
              pub_id: parietal.pub_id
              board_id: parietal.board_id
              date: parietal.date
              visitor_id: parietal.visitor_id
              host_id: parietal.host_id
              time_start: parietal.time_start
              open: parietal.open
            req.app.io.broadcast "parietal added", res
            callback true, null

  "create-session": (req, callback) ->
    req.models.checkinSession.exists
      board_id: req.param "boardId"
      date: new Date req.param "date"
      type: req.param "type"
      dorm: req.param "dorm"
    , (err, exists) ->
      if err?
        callback false, err
      else if exists
        callback false, "Session Already Exists"
      else
        req.models.checkinSession.create
          board_id: req.param "boardId"
          date: new Date req.param "date"
          type: req.param "type"
          dorm: req.param("dorm")
          open: false
        , (err,res) ->
          if err?
            callback false, err
          else
            session =
              pub_id: res.pub_id
              board_id: res.board_id
              date: res.date
              type: res.type
              open: res.open
              dorm: res.dorm

            req.models.checkout.find
              board_id: res.board_id
              open: true
            , (err, checkouts) ->
                req.models.student.find
                  pub_id: "#" if req.param("custom")
                  room: orm.ne(null) if not res.dorm?
                  house: res.dorm if res.dorm?
                , (err, students) =>
                  toInsert = []
                  for student in students
                    item =
                      checkin_id: res.pub_id
                      student_id: student.pub_id
                      state: 1
                    toInsert.push item
                  for checkout in checkouts
                    for item in toInsert
                      if checkout.student_id is item.student_id
                        item.state = if checkout.type is "DX" then 2 else 3

                  req.models.studentStatus.create toInsert
                  , (err,statuses) ->
                    console.log statuses
                    if err?
                      callback false, err
                    if err? and not statuses?
                      callback false, err
                    else
                      req.app.io.broadcast "session created", session
                      callback true, session

  "update-board-state": (req, callback) ->
    req.models.weekendBoard.one
      pub_id: req.param "boardId"
    , (err, board) ->
      if err?
        callback false, err
      else if not board?
        callback false, "Board not found"
      else
        board.open = req.param("open") is "true"
        board.save (err) ->
          if err?
            callback false, err
          else
            req.app.io.broadcast "board update", board
            callback true, null

  "update-session-state": (req, callback) ->
    req.models.checkinSession.one
      pub_id: req.param "sessionId"
    , (err, session) ->
      if err?
        callback false, err
      else if not session?
        console.log err
        callback false, "Session not found"
      else
        session.open = req.param("open") is "true"
        session.save (err) ->
          if err?
            callback false, err
          else
            req.app.io.broadcast "session update", session
            callback true, null

  "add-tocheckin": (req, callback) ->
    req.models.studentStatus.exists
      student_id: req.param "student_id"
      checkin_id: req.param "checkin_id"
    , (err, exists) ->
      if err?
        callback false, err
      else if exists
        callback false, "Student is already set for checkin"
      else
        req.models.studentStatus.create
          student_id: req.param "student_id"
          checkin_id: req.param "checkin_id"
          state: 1
          notes: null
        , (err, status) ->
          if err? and not status?
            callback false, err
          else
            callback true, null
            res =
              student_id: status.student_id
              checkin_id: status.checkin_id
              state: status.state
            req.app.io.broadcast "add checkin",res

  "remove-tocheckin": (req, callback) ->
    req.models.studentStatus.one
      student_id: req.param "student_id"
      checkin_id: req.param "checkin_id"
    , (err, status) ->
      if err?
        callback false, err
      else if not status?
        callback false, "Student was not set for checkin"
      else
        status.remove (err) ->
          if err?
            callback false, err
          else
            callback true, null
            res =
              student_id: status.student_id
              checkin_id: status.checkin_id
              state: status.state
            req.app.io.broadcast "remove checkin", res

  "get-permissions": (req, callback) ->
    req.models.studentPermissions.one
      student_id: req.param "student_id"
    , (err, res) =>
      helpers.respondErrorDuplicates err, res, true, callback, (res) =>
        callback true, res

  "update-student": (req, callback) ->
    req.models.checkinSession.one
      pub_id: req.param "sessionId"
    , (err, session) ->
      if err?
        callback false, err
      else if not session?
        callback false, "No such session"
      else if not session.open?
        callback false, "Session Not Open"
      else
        req.models.studentStatus.one
          checkin_id: req.param "sessionId"
          student_id: req.param "studentId"
        , (err, status) ->
          if err?
            callback false, err
          else if not status?
            callback false, "Student not eligable for checkin"
          else
            status.state = parseInt req.param "studentState"
            status.save (err) ->
              if err?
                console.log err
                callback false, err
              else
                callback true, null
                resStatus =
                  pub_id: status.pub_id
                  student_id: status.student_id
                  checkin_id: status.checkin_id
                  state:      status.state
                  notes:      status.notes
                req.app.io.broadcast "update student", resStatus
