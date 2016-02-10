orm = require "orm"
fs = require "fs"
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
        date_end = date.setDate date.getDate + 2
        req.models.checkinSession.create
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

  "load-session-data": (req, callback) ->
    req.models.checkinSession.one
      board_id: req.param "boardId"
      date: new Date req.param "date"
      type: req.param "type"
    , (err, res) ->
      if err?
        callback false, err
      else if not res?
        callback false, "Session Not Found"
      else
        session =
          pub_id: res.pub_id
          date: res.date
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

  "create-session": (req, callback) ->
    req.models.checkinSession.exists
      board_id: req.param "boardId"
      date: new Date req.param "date"
      type: req.param "type"
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
            req.models.student.find
              room: orm.ne null
            , (err, students) ->
              toInsert = []
              for student in students
                item =
                  checkin_id: res.pub_id
                  student_id: student.pub_id
                  state: 1
                toInsert.push item

              req.models.studentStatus.create toInsert
              , (err,statuses) ->
                if err? and not statuses?
                  console.log err
                  callback false, err
                else
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
        session.save (err) ->
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
