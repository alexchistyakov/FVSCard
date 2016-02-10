StudentStatus =
  present:
    name: "present"
    id: 0
    bgcolor: "#33CC33"
    text: "Checked in"
  missing:
    name: "missing"
    id: 1
    bgcolor: "#FF3300"
    text: "Missing"
  dx:
    name: "dx"
    id: 2
    bgcolor: "#0033CC"
    text: "DX"
  wx:
    name: "wx"
    id: 3
    bgcolor: "#0099FF"
    text: "WX"

SessionStatus =
  notInSession:
    id: 0
    elements:
      openSession:
        html: "<div class=\"button-manipulate-session\">Open</div>"
        action: ->
          window.FVSCard.dataManager.beginLoadBoard()
      createSession:
        html: "<div class=\"button-manipulate-session\">Create</div>"
        action: ->
          window.FVSCard.dataManager.beginCreateBoard()
  inSession:
    id: 1
    elements:
      manipulate:
        html: null
        update: ->
          @html = "<div class=\"button-manipulate-session\">#{if window.FVSCard.dataManager.session.open then "Close" else "Open"}</div>"

        action: ->
          window.FVSCard.dataManager.beginFlipBoardStatus()
      exitSession:
        html: "<div class=\"button-manipulate-session\">Exit</div>"
        action: ->
          window.FVSCard.dataManager.beginExitBoard()

class FVSCardUI
  menuBarElementSelector: ".menubar-container"

  constructor: (uiData) ->
    @studentListItemHTML = uiData.studentitem
    @studentSideListItemHTML = uiData.studentitemmini
    @popupSessionInfoHTML = uiData.popup_createsession
    @popupConfirmDialogHTML = uiData.popup_closesession
    @popupMessageDialogHTML = uiData.popup_message
    @popupWeekendBoardInfoHTML = uiData.popup_opensession

    @menuBar = new FVSTopMenuBar()
    @sideContainerRight = new FVSSideContainer @
    @tabPane = new FVSBottomTabPane @
    @studentList = new FVSStudentListPane null
    screen = new FVSSideScreen @studentList, @
    screen.assignSearchbar new FVSStudentSearchBar null, @
    @studentList.setScreen screen
    @tabPane.setScreen screen

  updateScreens: ->
    @studentList.triggerUpdate()
    @tabPane.update()

  generateStatusSwitchView: (student) ->
    $statusSwitcher = $ "<div class=\"status-switcher-container\">"
    statuses = []
    for k,v of StudentStatus
      statuses.push v
    for i in [0...statuses.length]
      do (i) =>
        status = statuses[i]
        styling = "width:#{100/statuses.length}%; background:#{status.bgcolor};"
        if i is 0
          styling += "border-radius: 10px 0 0 10px;"
        else if i is statuses.length-1
          styling += "border-radius: 0 10px 10px 0;"
        $element = $ "<div class=\"status-switcher\" style=\"#{styling}\">#{status.text}</div>"
        $element.click (event)=>
          window.FVSCard.dataManager.sendUpdateStudentStatus student, status
        $statusSwitcher.append $element
    $statusSwitcher

  update: ->
    @menuBar.update()
    @tabPane.update()
    @studentList.triggerUpdate()

  showConfirmDialog: (callback)->
    popup = new FVSPopupConfirmDialog @popupConfirmDialogHTML,callback
    popup.render()

  showMessageDialog: (title, message)->
    popup = new FVSPopupMessageDialog title,message, @popupMessageDialogHTML
    popup.render()

  showSessionInfoPopup: (title, callback) ->
    popup = new FVSPopupSessionDataInput title, @popupSessionInfoHTML, callback
    popup.render()

  showBoardInfoPopup: (title, callback) ->
    popup = new FVSPopupWeekendBoardDataInput title, @popupWeekendBoardInfoHTML, callback
    popup.render()

class FVSSideContainer
  readerContainerSelector: ".side-container-right .reader-container"
  readerMessageSelector: ".side-container-right .reader-container .reader-info-container .reader-message"
  readerActionContainerSelector: ".side-container-right .reader-container .reader-info-container .reader-action-container"

  inputHtml: "<input class=\"reader-input\" id=\"reader-input\" placeholder=\"Enter Reader ID\">"
  boundHtml: "<div class=\"reader-status\" style=\"background:#0F0;\">Reader Bound</div>"
  #TODO LOCKS

  constructor: (ui) ->
    @ui = ui
    @bound = false

  readerBound: (code) ->
    @bound = true
    $readerMessage = $ @readerMessageSelector
    $actionContainer = $ @readerActionContainerSelector
    $readerMessage.css "color", "#000"

    $readerMessage.text "You are now bound to a reader and will recieve updates."
    $actionContainer.empty()
    $actionContainer.append $ @boundHtml

  readerUnbound: ->
    @bound = false
    $readerMessage = $ @readerMessageSelector
    $actionContainer = $ @readerActionContainerSelector
    $readerMessage.css "color", "#000"

    $readerMessage.text "No reader is bound. Please input a reader ID bellow and press enter."
    $actionContainer.empty()
    $input = $ @inputHtml
    $input.keypress (event)-> #TODO
      if event.which is 13
        event.preventDefault()
        window.FVSCard.dataManager.submitRequestBindReader $input.val()

    $actionContainer.append $input

  showReaderError: (message) ->
    $readerMessage = $ @readerMessageSelector
    $readerMessage.css "color", "#f00"
    $readerMessage.text "Error: "+message

class FVSTopMenuBar
  buttonContainerSelector: ".menubar-container-top .button-container"
  statusLabelSelector: ".menubar-container-top .status-label"
  actionSwitcherSelector: "#action-switcher"

  constructor: (tabPane) ->
    @tabPane = tabPane

  update: ->
    if @board?
      @updateState SessionStatus.inSession
      @updateLabel "Weekend Board - " + moment(new Date @board.date_start).format("MMMM Do YYYY") +" - "+moment(new Date @board.date_end).format("MMMM Do YYYY")+ " - " + if @board.open then "Open" else "Not Open"
      $(@actionSwitcherSelector).show()
    else
      @updateState SessionStatus.notInSession
      @updateLabel "No Weekend Board Loaded"
      $(@actionSwitcherSelector).hide()

    $buttonContainer = $ @buttonContainerSelector
    $buttonContainer.empty()
    for key,element of @state.elements
      element.update() if element.update?
      $element = $ element.html
      $element.click element.action
      $buttonContainer.append $element

  updateState: (state)->
    @state = state

  updateLabel: (text)->
    $statusLabel = $ @statusLabelSelector
    $statusLabel.text text

  enterWeekendBoard: (board)->
    @board = board
    @update()

  exitWeekendBoard: ->
    @board = null
    @update()

class FVSBottomTabPane
  tabScreenMap: []
  currentIndex: 0

  constructor: (ui) ->
    @tabPaneSelector = ".list-container"
    @tabHandleSelector = @tabPaneSelector+" .tabhandle .tab-container"
    @ui = ui

  setScreen: (screen) ->
    @screen = screen

  update: ->
    @screen.update()

class FVSStudentListPane

  listSelector: ".main-container .student-lists .lists-body"
  tabHandleSelector: "#lists-tab-handle"
  titleSelector: "#lists-title"

  constructor: (screen) ->
    @setScreen screen

  setScreen: (screen) ->
    @screen = screen
    if @screen?
      $(@titleSelector).text @screen.name

  triggerUpdate: ->
    @render()

  render: ->
    $studentList = $ @listSelector
    $tabHandle = $ @tabHandleSelector

    @screen.renderTabHandle $tabHandle
    @screen.renderList $studentList

class FVSScreen
  tabListMap: []
  currentIndex: 0

  constructor: (name,parent, ui) ->
    @name = name
    @parent = parent
    @ui = ui
    @searching = false

  assignSearchbar: (searchbar, searchBarSelector) ->
    @searchBar = searchbar
    $searchBar = $(searchBarSelector)
    $searchBar.on "input", =>
      @searchBar.onType $searchBar.val()
      @onSearchInput $searchBar.val()
      @parent.triggerUpdate()

  onSearchInput: (input) ->
    if input.length != 0
      @searching = true
    else
      @searching = false

  setDisplayList: (tab) ->
    for i in [0...@tabListMap.length]
      if @tabListMap[i].name is tab
        @currentIndex = i
        @searchBar.setList @tabListMap[@currentIndex]
        return @currentIndex

  addDisplayList: (tab,list) ->
    @tabListMap.push list
    list

  update: ->
    @parent.triggerUpdate()

  renderList: ($tabPaneList)->
    @searchBar.regenerateTags()
    $tabPaneList.empty()
    toRender = if @searching then @searchBar.searchList else @tabListMap[@currentIndex]
    $tabPaneList.append toRender.render()

  renderTabHandle: ($tabHandle)->
    $tabHandle.empty()
    for item in @tabListMap
        do (item) =>
          $element = $ "<li class=\"tab\">#{item.name}</li>"
          if @tabListMap[@currentIndex] is item
            $element.addClass("active")
          $element.click =>
            @setDisplayList item.name
            @update()
          $tabHandle.append $element

class FVSSideScreen extends FVSScreen

  constructor: (tabPane, ui) ->
    super "Students", tabPane, ui
    @assignSearchbar new FVSStudentSearchBar(@tabListMap[@currentIndex], @ui), "#student-searchbar"

  addDisplayList: (tab, list) ->
    list.mini = true
    @tabListMap.push list
    list

class FVSCheckinScreen extends FVSScreen

  constructor: (tabPane, ui) ->
    super "Checkin",tabPane, ui
    @assignSearchbar new FVSStudentSearchBar null, @ui

class FVSStudentSearchBar

  constructor: (studentList, ui) ->
    @tags = []
    @studentList = if studentList? then studentList else new FVSStudentList @ui, ""
    @ui = ui
    @searchList = new FVSStudentList ui,""
    if studentList?
      @searchList.mini = studentList.mini
    @regenerateTags()

  setList: (students) ->
    @studentList = students
    @searchList.setAllowRemovals @studentList.allowRemovals
    @searchList.onRemove = (student) =>
      @studentList.onRemove student
      @studentList.removeStudentFromList student
    @searchList.mini = @studentList.mini
    @regenerateTags()

  regenerateTags: ->
    @tags = []
    for student in @studentList.students
      @tags.push student.firstName+" "+student.lastName

  onType: (text) ->
    @searchList.clearList()
    for i in [0...@tags.length]
      if @tags[i].toLowerCase().includes text.toLowerCase()
        @searchList.addStudentToList @studentList.students[i]

class FVSPopup
  overlay: "<div class=\"popup-overlay\"></div>"
  popupContentSelector: ".popup .popup-content"

  constructor: (baseHTML, title) ->
    @title = title
    @baseHTML = baseHTML

  element: ->
    console.log @baseHTML
    $element = $(@baseHTML)
    $element.find(".popup-title").text @title
    $element.find(".popup-button-container .ok-button").click @submit
    $element.find(".popup-button-container .cancel-button").click @dump
    $element

  render: ->
    $("body").append @element()
    $("body").append $ @overlay

  submit: =>
    return

  dump: ->
    $(".popup").remove()
    $(".popup-overlay").remove()

class FVSPopupMessageDialog extends FVSPopup

  constructor: (title, message, baseHTML) ->
    super baseHTML, title
    @message = message
    @submit = @dump

  element: ->
    $element = super()
    $element.find(".popup-button-container .cancel-button").remove()
    $element.find(".popup-content").text @message
    console.log $element
    $element

class FVSPopupSessionDataInput extends FVSPopup
  datePickerSelector: "#createsession-datepicker"
  typePickerSelector: ".popup-content .createsession-typeselector"

  constructor: (title, baseHTML, callback) ->
    super baseHTML,title
    @callback = callback

  element: ->
    $element = super()
    $element.find(@typePickerSelector).buttonset()
    $element.find(@datePickerSelector).datepicker()
    $element

  submit: =>
    selected = $('input[name=radio]:checked').attr('id')
    console.log selected
    tod = $('label[for="'+selected+'"]').text()
    console.log tod
    date = $(@datePickerSelector).val()
    @dump()

    @callback tod,date

class FVSPopupWeekendBoardDataInput extends FVSPopup
  datePickerSelector: "#createboard-datepicker"

  constructor: (title, baseHTML, callback) ->
    super baseHTML, title
    @callback = callback

  element: ->
    $element = super()
    $element.find(@datpickerSelector).datepicker
      beforeShowDay: (jdate)->
        date = moment(jdate)
        if date.isoWeekday() is 6 or date.isoWeekday() is 7
          return [true, "", "Available"]
        return [false, "", "unAvailable"]
  submit: =>
    date = $(@datePickerSelector).val()
    @callback date

class FVSPopupConfirmDialog extends FVSPopup
  constructor: (baseHTML, callback) ->
    super baseHTML, "Are you sure?"
    @callback = callback

  submit: =>
    @dump()
    @callback()

class FVSStudent

  constructor: (firstName, lastName, nickname, year, dorm, room, cardId, pub_id) ->
    @firstName = firstName
    @lastName  = lastName
    @nickname  = nickname
    @year      = year
    @dorm      = dorm
    @room      = room
    @cardId    = cardId
    @pub_id    = pub_id

    @status    = StudentStatus.missing
    @eligableForCheckin = false

  setStatusById: (id) ->
    for k,status of StudentStatus
      if status.id is id
        @status = status

class FVSStudentList
  studentListSelector: ".list-container .student-list"

  constructor: (ui, name) ->
    @ui = ui
    @name = name
    @students = []
    @allowRemovals = false
    @mini = false

  addAll: (students) ->
    for student in students
      @addStudentToList student

  setAllowRemovals: (allowRemovals) ->
    @allowRemovals = allowRemovals

  addStudentToList: (student) ->
    if student instanceof FVSStudent
      @students.push student

  pushStudentToList: (student) ->
    if student instanceof FVSStudent
      @students.unshift student

  removeStudentFromList: (student) ->
    for i in [0...@students.length]
      if student instanceof String
        if @students[i].firstName is student or @students[i].lastName is student
          @students.splice i, 1
      else
        if @students[i] is student
          @students.splice i, 1

  clearList: ->
    @students = []

  render: ->
    renderedList = []
    for student in @students
      do (student) =>
        unless @mini
          itemTemplate = $ @ui.studentListItemHTML
          $name = itemTemplate.find(".pane-info .name")
          $dorm = itemTemplate.find(".pane-info .dorm")
          itemTemplate
            .find(".pane-info .status")
            .text(student.status.text)
            .css("background-color", student.status.bgcolor)
          if window.FVSCard.dataManager? and window.FVSCard.dataManager.session?
            if student.eligableForCheckin
              itemTemplate.find(".button-add-checkin").remove()
              itemTemplate.find(".pane-info .status").click (event)=>
                $(event.target).replaceWith @ui.generateStatusSwitchView student
            else
              itemTemplate.find(".button-add-checkin").click =>
                FVSCard.dataManager.submitEligableCheckin student, true

          else
            itemTemplate.find(".pane-info .status").remove()
            itemTemplate.find(".button-add-checkin").remove()
        else
          itemTemplate = $ @ui.studentSideListItemHTML
          $name = itemTemplate.find ".pane-info .student-name"
          $dorm = itemTemplate.find ".pane-info .student-dorm"
          itemTemplate
            .find(".pane-info .student-indicator")
            .css("color", student.status.bgcolor)

        $name.text student.firstName+" \""+student.nickname+ "\" "+student.lastName+" '"+student.year.substring(2)
        $dorm.text ( if student.dorm is "DAY" then "Day Student" else student.dorm )+" "+(if student.room? then student.room else "")

        $closeButton = itemTemplate.find(".button-close")

        if @allowRemovals
          $closeButton.click =>
            @removeStudentFromList student
            @ui.tabPane.updateLists()
            @onRemove student
        else
          $closeButton.css "display", "none"

        renderedList.push itemTemplate
    renderedList

class FVSCardDataManager

  constructor: (ui, data, request) ->
    @ui = ui
    @students = []
    @lists = []
    @request = request
    for student in data.students
      @students.push new FVSStudent student.firstName, student.lastName, student.nickname, student.year, student.dorm,student.room, student.card_id, student.pub_id

    @socket = io.connect "http://localhost"
    @socket.on "session update", @sessionUpdate
    @socket.on "update student", @updateStudentStatus
    @socket.on "add checkin", @addEligableToCheckin
    @socket.on "remove checkin", @removeEligableToCheckin
    @socket.on "reader update", @readerUpdate
    @socket.on "reader bind", @readerBind
    @socket.on "board update", @boardUpdate
    @socket.on "reader disconnected", @readerDisconnected

  createList: (name,students) ->
    list = new FVSStudentList @ui,name
    list.addAll students
    @lists.push list
    list

  removeList: (name) ->
    for i in [0...@lists.length]
      if @lists[i].name is name
        @lists.splice i,1
        return

  addToList: (name, student, toStart) ->
    list = @findList name
    console.log @lists
    if list?
      if toStart
        list.pushStudentToList student
      else
        list.addStudentToList student

  removeFromList: (name, student) ->
    list = @findList name
    if list?
      list.removeStudentFromList student

  findList: (name) ->
    for list in @lists
      if list.name is name
        return list

  submitRequestBindReader: (key) =>
    @socket.emit "request bind",
      key: key

  submitBreakBindReader: (key) =>
    @socket.emit "break bind"

  readerBind: (data) =>
    console.log data
    if data.success
      @ui.sideContainerRight.readerBound data.data
    else
      @ui.sideContainerRight.showReaderError data.data

  readerDisconnected: =>
    @ui.sideContainerRight.readerUnbound()

  inList: (student,name) ->
    list = @findList name
    console.log list
    for res in list.students
      if res.pub_id is student.pub_id
        return true
    return false

  findStudent: (id) ->
    for student in @students
      if student.pub_id is id
        return student

  resetStudents: ->
    for student in @students
      student.status = StudentStatus.missing

  updateUi: ->
    @ui.updateScreens()

  submitCreateSession: (tod, date)=>
    mDate = moment date,"MM/DD/YYYY"
    @request
      command: "create-session"
      type: tod
      date: mDate.toDate()
    , "GET", (response) =>
      if not response.success and response.data?
        @ui.showMessageDialog "Error",response.data
      else if response.data?
        @submitLoadSession response.data.type,moment(response.data.date).format "MM/DD/YYYY"

  flipStateAndSubmit: =>
    console.log @session
    @submitUpdateSession !@session.open

  submitUpdateSession: (state)=>
    console.log state
    if @session?
      @request
        command: "update-session-state"
        sessionId: @session.pub_id
        open: state
      , "GET", (response) ->
        if not response.success and response.data?
          @ui.showMessageDialog "Error",response.data

  submitEligableCheckin: (student, eligable)=>
    if @session?
      @request
        command: "#{if eligable then "add" else "remove"}-tocheckin"
        student_id: student.pub_id
        checkin_id: @session.pub_id
      , "GET", (response) ->
        if not response.success and response.data?
          @ui.showMessageDialog "Error",response.data

  submitLoadSession: (tod, date) =>
    mDate = moment date,"MM/DD/YYYY"
    @request
      command: "load-session-data"
      date: mDate.toDate()
      type: tod
    , "GET", (response) =>
      if not response.success and response.data?
        @ui.showMessageDialog "Error",response.data
      else if response.data?
        @enterSession response.data

  beginCreateSession: ->
    @ui.showSessionInfoPopup("Create Session",@submitCreateSession)

  beginFlipSessionStatus: ->
    @ui.showConfirmDialog(@flipStateAndSubmit)

  beginLoadSession: ->
    @ui.showSessionInfoPopup "Load Session",@submitLoadSession

  beginCreateBoard: ->
    @ui.showBoardInfoPopup "Create New Weekend Board", @submitCreateBoard

  beginLoadBoard: ->
    @ui.showBoardInfoPopup "Load Weekend Board", @submitLoadBoard

  beginExitSession: ->
    @ui.showConfirmDialog(@exitSession)

  enterSession: (res) =>
    console.log res
    @session = res.session
    @ui.menuBar.enterSession res.session
    @createList("Session", [])
    toCheckin = @createList("To Checkin", [])
    toCheckin.setAllowRemovals true
    toCheckin.onRemove = (student) =>
      @submitEligableCheckin student, false

    for status in res.students
      student = @findStudent status.student_id
      student.setStatusById status.status
      student.eligableForCheckin = true
      @addToList "To Checkin", student, false
      @sessionSort student
    @ui.tabPane.screen.updateList()

  sessionSort: (student)=>
    if @session?
      if student.status.id is 1
        #TODO
        @removeFromList "To Checkin", student
        @removeFromList "Session", student
        @addToList "To Checkin", student, true
      else
        #TODO
        @removeFromList "Session", student
        @removeFromList "To Checkin", student
        @addToList "Session", student, true

  exitSession: =>
    @session = null
    @ui.tabPane.screen.currentIndex = 0
    @removeList "Session"
    @removeList "To Checkin"
    @resetStudents()
    @ui.menuBar.exitSession()
    @ui.tabPane.screen.updateList()

  addEligableToCheckin: (status) =>
    if @session? and @session.pub_id is status.checkin_id
      student = @findStudent status.student_id
      unless student.eligableForCheckin
        student.eligableForCheckin = true
        @addToList "To Checkin", student, true
        @ui.tabPane.screen.updateList()

  removeEligableToCheckin: (status) =>
    if @session? and @session.pub_id is status.checkin_id
      student = @findStudent status.student_id
      if student.eligableForCheckin
        student.eligableForCheckin = false
        @removeFromList "To Checkin", student
        @ui.tabPane.screen.updateList()

  sessionUpdate: (session) =>
    if @session? and @session.pub_id is session.pub_id
      @session.open = session.open
      @ui.update()

  updateStudentStatus: (status) =>
    if @session? and @session.pub_id is status.checkin_id
      student = @findStudent status.student_id
      if student?
        student.setStatusById status.state
        @sessionSort student
        @ui.tabPane.screen.updateList()

  sendUpdateStudentStatus: (student, status) ->
    unless student.status is status
      @request
        command: "update-student"
        sessionId: @session.pub_id
        studentId: student.pub_id
        studentState: if typeof status is "integer" then status else status.id
        studentNotes: null #TODO
      , "GET", (res) ->
        return
    else
      @ui.tabPane.screen.updateList()

  class FVSCard

    constructor: (request, uiData, data) ->
      @fvsCardRequest = request
      @state = SessionStatus.notInSession

      @ui = new FVSCardUI uiData
      @dataManager = new FVSCardDataManager @ui, data, request

      allStudents = @dataManager.createList "All Students", @dataManager.students
      day = @dataManager.createList "Day", []
      bList = @dataManager.createList "Boarding", []
      for student in @dataManager.students
        if student.dorm is "DAY"
          @dataManager.addToList "Day", student, false
        else
          @dataManager.addToList "Boarding", student, false
      @ui.studentList.screen.addDisplayList "All Students", allStudents
      @ui.studentList.screen.addDisplayList "Day",day
      @ui.studentList.screen.addDisplayList "Boarding", bList
      @dataManager.updateUi()

      @ui.menuBar.exitSession()
      @ui.sideContainerRight.readerUnbound()
      @ui.tabPane.screen.setDisplayList "All Students"


  window.FVSCard =
    init: (request, ui, data) ->
      window.FVSCard = new FVSCard request, ui, data
