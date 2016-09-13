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
    text: "Absent"
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

OpenClosedStatus = [
      name: "open"
      id: 0
      bgcolor: "#33CC33"
      text: "Open"
    ,
      name: "closed"
      id: 1
      bgcolor: "#FF3300"
      text: "Closed"
    ]
BoardStatus =
  notInBoard:
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
  inBoard:
    id: 1
    elements:
      manipulate:
        html: null
        update: ->
          @html = "<div class=\"button-manipulate-session\">#{if window.FVSCard.dataManager.board.open then "Close" else "Open"}</div>"

        action: ->
          window.FVSCard.dataManager.beginFlipBoardStatus()
      exitSession:
        html: "<div class=\"button-manipulate-session\">Exit</div>"
        action: ->
          window.FVSCard.dataManager.beginExitBoard()

class FVSCardUI
  menuBarElementSelector: ".menubar-container"

  constructor: (uiData, dataManager) ->
    @dataManager = dataManager
    @studentListItemHTML = uiData.studentitem
    @studentSideListItemHTML = uiData.studentitemmini
    @parietalItem = uiData.parietalitem
    @dxwxItem = uiData.dxwxitem
    @studentIconItem = uiData.studenticonitem
    @studentplaceholder = uiData.studentplaceholder
    @popupSessionInfoHTML = uiData.popup_createsession
    @popupConfirmDialogHTML = uiData.popup_closesession
    @popupMessageDialogHTML = uiData.popup_message
    @popupWeekendBoardInfoHTML = uiData.popup_loadboard

    @sideContainerRight = new FVSSideContainer @
    @tabPane = new FVSBottomTabPane @, uiData.checkin_manipulator
    @menuBar = new FVSTopMenuBar @tabPane
    @studentList = new FVSStudentListPane null
    screen = new FVSSideScreen @studentList, @
    @studentList.setScreen screen

  updateScreens: ->
    @studentList.triggerUpdate()
    @tabPane.triggerUpdate()

  createStudentIconView: (student) ->
    $element = $ @studentIconItem
    $element.find(".student-photo").attr "src", if student.photoSource? then student.photoSource else "/img/missing.png"
    $element.find(".student-name").text "#{student.firstName} #{student.lastName}"
    $element.find(".student-dorm").text student.dorm
    $element

  postAction: (action) ->
    @listAction = action
    @studentList.screen.setActionButtonVisible true
    @studentList.triggerUpdate()

  clearAction: =>
    @listAction = null
    @studentList.screen.setActionButtonVisible false
    @studentList.triggerUpdate()

  generateStatusSwitchView: (student) ->
    statuses = []
    for k,v of StudentStatus
      statuses.push v
    @generateSwitchPill student, statuses, (student, status) ->
      window.FVSCard.dataManager.sendUpdateStudentStatus student, status

  generateSwitchPill: (object, statuses, action) ->
    $statusSwitcher = $ "<div class=\"status-switcher-container\">"
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
          action object, status
        $statusSwitcher.append $element
    $statusSwitcher

  update: ->
    @menuBar.update()
    @tabPane.triggerUpdate()
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

  showTimepickerPopup: (title, callback) ->
    popup = new FVSPopupTimepickerDialog title, @popupWeekendBoardInfoHTML, callback
    popup.render()

  createPermissionsHint: (student) ->
    $element = $ "<table/>"
    #TODO


class FVSSideContainer
  readerContainerSelector: ".side-container-right .reader-container"
  readerMessageSelector: ".side-container-right .reader-container .reader-info-container .reader-message"
  readerActionContainerSelector: ".side-container-right .reader-container .reader-info-container .reader-action-container"
  readerIconSelector: ".reader-icon .reader-image"

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
    $readerIcon = $ @readerIconSelector
    $readerMessage.css "color", "#000"

    $readerMessage.text "You are now bound to a reader and will recieve updates."

    $actionContainer.empty()
    $actionContainer.append $ @boundHtml

  readerUnbound: ->
    @bound = false
    $readerMessage = $ @readerMessageSelector
    $actionContainer = $ @readerActionContainerSelector
    $readerIcon = $ @readerIconSelector
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
  statusLabelSelector: ".menubar-container-top .status-container .status-label"
  actionSwitcherSelector: "#action-switcher"

  constructor: (tabPane) ->
    @tabPane = tabPane
    @currentIndex = 0
    @prevInBoard = false
    @updateState BoardStatus.notInBoard
    $actionSwitcher = $(@actionSwitcherSelector)
    $actionSwitcher.find("li").each (index, element) =>
      $(element).click =>
        unless @currentIndex is index
          @tabPane.setScreen index
          @currentIndex = index
          @update()

  update: ->
    console.log "THINGS"
    $actionSwitcher = $(@actionSwitcherSelector)
    $actionSwitcher.find("li").each (index, element) =>
      if @currentIndex is index
        $(element).addClass "pressed"
      else
        $(element).removeClass "pressed"
    unless @board? is @prevInBoard
      if @board?
        @updateState BoardStatus.inBoard
        @updateLabel "Weekend Board - " + moment(new Date @board.date_start).format("MMMM Do YYYY") + " - " + moment(new Date @board.date_end).format("MMMM Do YYYY") + " - " + if @board.open then "Open" else "Not Open"
        $actionSwitcher.show()
        @prevInBoard = true
      else
        @updateState BoardStatus.notInBoard
        @updateLabel "No Weekend Board Loaded"
        $actionSwitcher.hide()
        @prevInBoard = false

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
  tabHandleSelector: "#tab-container"
  listContainerSelector: ".main-container .list-container .bottom-container .student-list"
  tabScreenMap: []
  tabScreenMapCache: []
  currentScreenIndex: 0

  constructor: (ui, checkinManipulator) ->
    @ui = ui
    @checkinManipulator = checkinManipulator
    @resetScreens()

  resetScreens: =>
    @tabScreenMap[0] = new FVSParietalScreen @, @ui
    @tabScreenMap[1] = new FVSCheckinScreen @, @ui, @checkinManipulator
    @tabScreenMap[2] = new FVSCheckoutScreen @, @ui

  setScreen: (screen) ->
    if @screen?
      @saveCurrentScreenState()
      @screen.unrender()
      @screen.disableSearch()
    @screen = @tabScreenMap[screen]
    @currentScreenIndex = screen
    if @screen?
      if not @screen.loaded then @screen.load()
      @screen.enableSearch()
    if @tabScreenMapCache[screen]?
      @loadScreenState screen
      @screen.updateScreenData()
      @screen.renderTabHandle $ @tabHandleSelector
    else
      @triggerUpdate()

  saveCurrentScreenState: ->
    console.log "DICK"
    @tabScreenMapCache[@currentScreenIndex] = $(".student-list").clone true

  loadScreenState: (slot) ->
    $(".student-list").empty()
    $(".student-list").replaceWith @tabScreenMapCache[slot]

  triggerUpdate: ->
    @render()

  render: ->
    @updateListData()
    $(@tabHandleSelector).empty()
    if @screen?
      @screen.renderTabHandle $ @tabHandleSelector
      @screen.updateScreenData()

  updateListData: ->
    $(@listContainerSelector).empty()
    if @screen?
      @screen.renderList $ @listContainerSelector

  reset: ->
    @screen.unrender()
    @screen.unload()
    @screen = null

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
      if not screen.loaded then @screen.load()

  addActionButton: ($button)->
    @screen.addButton $button

  clearActionButtons: ->
    @screen.clearButtons()

  triggerUpdate: ->
    @render()

  render: ->
    @updateListData()
    $tabHandle = $ @tabHandleSelector
    @screen.renderTabHandle $tabHandle

  updateListData: ->
    $studentList = $ @listSelector
    @screen.renderList $studentList

class FVSScreen
  constructor: (name,parent, ui) ->
    @name = name
    @parent = parent
    @ui = ui
    @searching = false
    @tabListMap = []
    @currentIndex = 0

    @tabClass = "screen-tab"
    @tabClassActive = "screen-tab-active"
    @tabClassOff = "screen-tab-off"

  assignSearchbar: (searchbar, searchBarSelector) ->
    @searchBar = searchbar
    @searchBarSelector = searchBarSelector
    @enableSearch()

  enableSearch: ->
    $searchBar = $(@searchBarSelector)
    $searchBar.on "input", (event)=>
      val = $(event.target).val()
      @searchBar.onType val
      @onSearchInput val
      @parent.updateListData()

  disableSearch: ->
    console.log @searchBarSelector
    $searchBar = $(@searchBarSelector)
    $searchBar.off "input"

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

  addDisplayList: (list) ->
    @tabListMap.push list
    list

  clearDisplayLists: ->
    @tabListMap = []

  update: ->
    @parent.triggerUpdate()

  renderList: ($tabPaneList)->
    @searchBar.regenerateTags()
    $tabPaneList.empty()
    toRender = if @searching then @searchBar.searchList else @tabListMap[@currentIndex]
    $tabPaneList.append toRender.render()

  updateScreenData: ->

  renderTabHandle: ($tabHandle)->
    $tabHandle.empty()
    for item in @tabListMap
        do (item) =>
          $element = $ "<li class=\"#{@tabClass} #{@tabClassOff}\">#{item.name}</li>"
          if @tabListMap[@currentIndex] is item
            $element.removeClass @tabClassOff
            $element.addClass @tabClassActive
          $element.click =>
            @setDisplayList item.name
            @update()
          $tabHandle.append $element

  load: ->
    @loaded = true
    @enableSearch()
    unless @loadLists?
      return
    for listName in @loadLists
      list = FVSCard.dataManager.findList(listName)
      if list?
        @addDisplayList list
      else
        @addDisplayList FVSCard.dataManager.createList listName, [], @listClass

  unrender: ->

  unload: ->
    @loaded = false
    @disableSearch()
    @clearDisplayLists()

  createButtonView: (id)->
    $element = $ "<div></div>"
    $element.text "+"
    $element.addClass "create-button"
    $element.addClass "createbutton"
    $element.attr "id", id
    $element

class FVSSideScreen extends FVSScreen

  constructor: (tabPane, ui) ->
    super "Students", tabPane, ui
    @assignSearchbar new FVSStudentSearchBar(@tabListMap[@currentIndex], @ui), "#student-searchbar"
    @tabClass = "tab"
    @tabClassActive = "active"
    @tabClassOff = ""
    @buttons = []

  addDisplayList: (list) ->
    list.mini = true
    @tabListMap.push list
    list

  load: ->
    super()

  addButton: (button)->
    @buttons.push button

  setLeavePermissionHintEnabled: (enabled) ->
    @leavePermissionHintEnabled = enabled

  clearButtons: ->
    @buttons = []

  setActionButtonVisible: (visible) ->
    @searchBar.searchList.setActionButtonEnabled visible
    @tabListMap[@currentIndex].setActionButtonEnabled visible

  renderList: ($listSelector) ->
    @searchBar.searchList.clearButtons()
    @tabListMap[@currentIndex].clearButtons()

    @searchBar.searchList.addButtons @buttons
    @tabListMap[@currentIndex].addButtons @buttons

    super $listSelector

class FVSCheckinScreen extends FVSScreen

  constructor: (tabPane, ui, manipulatorHTML) ->
    super "Checkin",tabPane, ui
    @assignSearchbar (new FVSStudentSearchBar @tabListMap[@currentIndex], @ui), "#main-searchbar"
    @manipulatorHTML = manipulatorHTML
    @loadLists = ["Checked In", "Absent"]
    @listClass = FVSStudentList

  renderList: ($tabPaneList) ->
    $tabPaneList.empty()
    unless FVSCard.dataManager.session?
      $tabPaneList.append "<div class=\"screen-label\">No Meal Check Currently Loaded</div>"
    else
      super $tabPaneList

  updateScreenData: ->
    $container = $ ".side-container-right"
    unless $container.has(".session-manipulator").length
      $container.append $ @manipulatorHTML
      $status = $("#status-manipulator")
      $(".session-manipulator-create").click FVSCard.dataManager.beginCreateSession
      $(".session-manipulator-load").click ->
        FVSCard.dataManager.submitLoadSession null,null,$(".session-manipulator-select").val()
      FVSCard.dataManager.getSessionList @populateList
    $status = $("#status-manipulator")
    $status.off "click"
    if FVSCard.dataManager.session?
      open = FVSCard.dataManager.session.open
      $status.css "background", if open then "#7AFF95" else "#FF7A7A"
      $status.text if open then "Open" else "Closed"
      $status.click FVSCard.dataManager.beginFlipSessionStatus
      @tabListMap[1].setAllowRemovals not open
      @ui.clearAction()
      if @currentIndex is 1 and not open
        @ui.postAction (student) =>
          FVSCard.dataManager.submitEligableCheckin student, true
    else
      $status.css "background", "#ccc"
      $status.text "No Session"

    $manipulator = $ ".session-manipulator"
    unless $manipulator.is ":visible"
      $manipulator.show()

  unrender: ->
    $manipulator = $ ".session-manipulator"
    $manipulator.hide()

  renderTabHandle: ($tabHandle) ->
    super $tabHandle
    unless FVSCard.dataManager.session?
      $tabHandle.find(".screen-tab").each (index, element)->
        $(element).addClass "tab-disabled"

        $(element).unbind "click"

  populateList: (data) =>
    $(".session-manipulator-select").empty()
    for session in data
      @addSessionEntry session

  addSessionEntry: (session) =>
    unless session.type is "Dorm"
      text = "#{moment(session.date).format "MMMM Do, dddd"} - #{session.type}"
    else
      text = "#{moment(session.date).format "MMMM Do, dddd"} - #{session.dorm}"
    element = $("<option></option>").val(session.pub_id).html(text)
    $(".session-manipulator-select").append element

class FVSCheckoutScreen extends FVSScreen

  constructor: (tabPane, ui) ->
    super "Checkouts", tabPane, ui
    @assignSearchbar (new FVSCheckoutSearchbar @tabListMap[@currentIndex], ui), "#main-searchbar"
    @loadLists = ["Off Campus", "Returned"]
    @listClass = FVSCheckoutList
    @inited = false

  load: ->
    super()
    FVSCard.dataManager.submitLoadCheckouts()

  renderList: ($listSelector) ->
    super $listSelector
    $pView = @createCheckoutMakeView()
    @wipCheckout.date = moment()
    $listSelector.prepend $pView
    $pView.hide()
    @updateCurrentCheckoutList()

  updateScreenData: ->
    unless @inited
      if @currentIndex is 0
        $element = @createButtonView "checkout-create-button"
        $element.click =>
          @flipCreateAction true
        $("#main-searchbar").css "width", "90%"
        $(".bottom-container .bottom-handle").append $element
        @inited = true
    unless @currentIndex is 0
      $("#checkout-create-button").hide()
      $("#main-searchbar").css "width", "100%"
    else
      $("#checkout-create-button").show()
      $("#main-searchbar").css "width", "90%"

  createCheckoutMakeView: =>
    @wipCheckout = new FVSCheckout null, null, moment().format("h:mm:ss a"), null, moment().format("MMMM Do YYYY")
    $element = $ @ui.dxwxItem
    $element.attr "id", "dxwx-create"
    $element.find(".c-student .button-container")
    $element.click ->
      $element.attr "tabindex", -1
    $element.keyup (event) =>
      if event.keyCode is 13
        @finalizeWipCheckout()
      if event.keyCode is 27
        @checkoutList.clearList()
        @updateCurrentCheckoutList()
        @dumpWipCheckout()

    @checkoutList = new FVSStudentList @ui, "Current Checkout"
    @checkoutList.mini = true
    @checkoutList.buttonless = true

    $input = $ "<input class=\"fancy-input\">"

    $typeSelector = $ "<select/>"
    $typeSelector.attr "id", "dxwx-type-selector"
    $typeSelector.attr "name", "dxwx-type-selector"
    $item = $("<option/>").text("DX")
    $typeSelector.append $item
    $typeSelector.append $item.clone().text "WX"
    $element.find(".dxwx-type").append $typeSelector

    $element.find(".dxwx-time-leave").append $input.clone().timepicker()
    $element.find(".dxwx-time-return").append $input.clone().timepicker()
    $element.find(".dxwx-date-leave").append $input.clone().datepicker()
    $element.find(".dxwx-date-return").append $input.clone().datepicker()
    $element.find(".dxwx-location").append $input.clone()
    $element.find(".dxwx-transport").append $input.clone()

    $element.find(".status").css "background", "#ccc"
    $element.find(".status").text "Working"
    $element

  dumpWipCheckout: ->
    @wipCheckout = null
    @flipCreateAction false

  finalizeWipCheckout: ->
    @wipCheckout.time_leave =  $(".dxwx-time-leave .fancy-input").val()
    @wipCheckout.time_return = $(".dxwx-time-return .fancy-input").val()
    @wipCheckout.date_leave = $(".dxwx-date-leave .fancy-input").val()
    @wipCheckout.date_return = $(".dxwx-date-return .fancy-input").val()
    @wipCheckout.location = $(".dxwx-location .fancy-input").val()
    @wipCheckout.transport = $(".dxwx-transport .fancy-input").val()
    @wipCheckout.type = $("#dxwx-type-selector").val()
    @wipCheckout.open = true
    for item in @checkoutList.items
      @wipCheckout.student = item
      FVSCard.dataManager.submitCreateCheckout @wipCheckout
    @dumpWipCheckout()

  flipCreateAction: (creating) ->
    $createButton = $("#checkout-create-button")
    $wipCheckoutView = $("#dxwx-create")
    if not creating
      $("#main-searchbar").css "width", "90%"
      $createButton.show()
      $wipCheckoutView.hide()
      @ui.clearAction()
    else
      $("#main-searchbar").css "width", "100%"
      $wipCheckoutView.show()
      $createButton.hide()
      @ui.postAction (student) =>
        @checkoutList.addItemToList student
        @updateCurrentCheckoutList()

  updateCurrentCheckoutList: ->
    $element = $ "#dxwx-create .c-student"
    $element.empty()
    $element.append @checkoutList.render()

  unrender: ->
    @ui.clearAction()
    $("#main-searchbar").css "width", "100%"
    $("#checkout-create-button").remove()
    @inited = false

class FVSParietalScreen extends FVSScreen

  constructor: (tabPane, ui) ->
    super "Parietals",tabPane,ui
    @assignSearchbar (new FVSParietalSearchBar @tabListMap[@currentIndex], ui), "#main-searchbar"
    @loadLists = ["Ongoing","Past"]
    @listClass = FVSParietalList
    @inited = false

  load: ->
    super()
    FVSCard.dataManager.submitLoadParietals()

  renderList: ($listSelector)->
    super $listSelector
    $pView = @createParietalMakeView()
    @wipParietal.date = moment()
    $listSelector.prepend $pView
    $pView.hide()

  updateScreenData: ->
    unless @inited
      if @currentIndex is 0
        $element = @createButtonView("parietal-create-button")
        $element.click =>
          @flipCreateAction true
        $("#main-searchbar").css "width", "90%"
        $(".bottom-container .bottom-handle").append $element
        @inited = true
    unless @currentIndex is 0
      $("#parietal-create-button").hide()
    else
      $("#parietal-create-button").show()

  unrender: ->
    $("#main-searchbar").css "width", "100%"
    $("#parietal-create-button").remove()
    @inited = false

  createParietalMakeView: =>
    @wipParietal = new FVSParietal null, null, moment().format("h:mm:ss a"), null, moment().format("MMMM Do YYYY")
    $element = $ @ui.parietalItem
    $element.attr "id", "p-create"
    $element.click ->
      $element.attr "tabindex", -1
    $element.keyup (event) =>
      if event.keyCode is 13
        @finalizeWipParietal()
      if event.keyCode is 27
        @dumpWipParietal()

    $placeholderHost = $ @ui.studentplaceholder
    $placeholderGuest = $ @ui.studentplaceholder
    $placeholderHost.click =>
      $placeholderHost.attr "tabindex", -1
      @ui.postAction (student)=>
        @wipParietal.host = student
        $("#p-create .student-to").empty().append @ui.createStudentIconView student
        $placeholderHost.removeAttr "tabindex"
    $placeholderHost.focusout =>
      setTimeout @ui.clearAction, 250
    $placeholderGuest.click =>
      $placeholderGuest.attr "tabindex", -1
      @ui.postAction (student)=>
        @wipParietal.guest = student
        $("#p-create .student-going").empty().append @ui.createStudentIconView student
        $placeholderGuest.removeAttr "tabindex"
    $placeholderGuest.focusout =>
      setTimeout @ui.clearAction, 250

    $element.find(".student-going").append $placeholderGuest
    $element.find(".student-to").append $placeholderHost
    $input = $ "<input class=\"fancy-input\">"
    $input.timepicker()

    $element.find(".p-time-start").append $input
    $element.find(".p-time-end .float-label").append $ "<span style=\"font-weight: italic;\"> Ongoing</span>"

    $element.find(".status").css "background", "#ccc"
    $element.find(".status").text "Working"
    $element

  finalizeWipParietal: ->
    @wipParietal.timeIn = $(".p-time-start .fancy-input").val()
    @wipParietal.date = moment()
    @wipParietal.open = true
    window.FVSCard.dataManager.submitCreateParietal @wipParietal
    @wipParietal = null
    @parent.updateListData()
    @dumpWipParietal()

  dumpWipParietal: ->
    @wipParietal = null
    @flipCreateAction false
    @clearPCreate()

  clearPCreate: ->
    #TODO
    @parent.triggerUpdate()

  flipCreateAction: (creating) ->
    $createButton = $("#parietal-create-button")
    $wipParietalButton = $("#p-create")
    if not creating
      $("#main-searchbar").css "width", "90%"
      $createButton.show()
      $wipParietalButton.hide()
    else
      $("#main-searchbar").css "width", "100%"
      $wipParietalButton.show()
      $createButton.hide()

class FVSSearchBar

  constructor: (list, ui, clazz) ->
    @tags = []
    @ui = ui
    @searchList = new clazz ui, ""
    if list? then @setList(list) else @setList(new clazz @ui, "")

  setList: (list) ->
    @list = list
    @searchList.setAllowRemovals @list.allowRemovals
    @searchList.onRemove = (item) =>
      @list.onRemove item
      @list.removeItemFromList student
    @regenerateTags()

  regenerateTags: ->

  onType: (text) ->
    @searchList.clearList()
    for i in [0...@tags.length]
      for j in [0...@tags[i].length]
        if @tags[i][j].toLowerCase().startsWith text.toLowerCase()
          @searchList.addItemToList @list.items[i]
          break

class FVSCheckoutSearchbar extends FVSSearchBar

  constructor: (list, ui) ->
    super list, ui, FVSCheckoutList

  regenerateTages: ->
    @tags = []
    for item in @list.items
      @tags.push [item.location, item.transport, item.student.firstName, item.student.lastName]

class FVSStudentSearchBar extends FVSSearchBar

  constructor: (studentList, ui) ->
    super studentList, ui, FVSStudentList
    if studentList?
      @searchList.mini = studentList.mini

  setList: (students) ->
    super students
    @searchList.mini = @list.mini

  regenerateTags: ->
    @tags = []
    for student in @list.items
      @tags.push [student.firstName, student.lastName]

class FVSParietalSearchBar extends FVSSearchBar

  constructor: (list, ui) ->
    super list, ui, FVSParietalList

  regenerateTags: ->
    @tags = []
    for item in @list.items
      @tags.push [item.host.firstName, item.host.lastName, item.guest.firstName, item.guest.lastName, item.guest.dorm, item.host.dorm]

class FVSPopup
  overlay: "<div class=\"popup-overlay\"></div>"
  popupContentSelector: ".popup .popup-content"

  constructor: (baseHTML, title) ->
    @title = title
    @baseHTML = baseHTML

  element: ->
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

class FVSPopupTimepickerDialog extends FVSPopup
  datePickerSelector: "#createboard-datepicker"

  constructor: (title, baseHTML, callback) ->
    super baseHTML, title
    @callback = callback

  element: ->
    $element = super()
    $element.find(@datePickerSelector).timepicker()
    $element

  submit: =>
    time = $(@datePickerSelector).val()
    @dump()

    @callback time

class FVSPopupMessageDialog extends FVSPopup

  constructor: (title, message, baseHTML) ->
    super baseHTML, title
    @message = message
    @submit = @dump

  element: ->
    $element = super()
    $element.find(".popup-button-container .cancel-button").remove()
    $element.find(".popup-content").text @message
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
    $element.find("#dorm-select").hide()
    $element.find("#session-name").hide()
    $element.find(".radio-buttons").click ->
      $e = $(".createsession-typeselector :radio:checked")
      $("#dorm-select").hide()
      $("#session-name").hide()
      if $e.attr("id") is "radio3"
        $("#dorm-select").show()
      else if $e.attr("id") is "radio4"
        $("#session-name").show()
    $element.find(@datePickerSelector).datepicker()
    $element

  submit: =>
    selected = $('input[name=radio]:checked').attr('id')
    tod = $('label[for="'+selected+'"]').text()
    date = $(@datePickerSelector).val()
    custom = false
    if tod is "Dorm"
      dorm = $("#dorm-select").val()
    else if tod is "Custom"
      custom = true
      tod = $("#session-name").val()
    @dump()

    @callback tod,custom,date,dorm

class FVSPopupWeekendBoardDataInput extends FVSPopup
  datePickerSelector: "#createboard-datepicker"

  constructor: (title, baseHTML, callback) ->
    super baseHTML, title
    @callback = callback

  element: ->
    $element = super()
    $element.find(@datePickerSelector).datepicker
      beforeShowDay: (jdate)->
        date = moment jdate
        if date.isoWeekday() is 6 or date.isoWeekday() is 7
          return [true, "", "Available"]
        return [false, "", "unAvailable"]
    $element

  submit: =>
    date = $(@datePickerSelector).val()
    @dump()
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

class FVSCheckout
  constructor: (student, date_leave, date_return, time_leave, time_return, location, transport, type, pub_id, open) ->
    @student = student
    @date_leave = date_leave
    @date_return = date_return
    @time_leave = time_leave
    @time_return = time_return
    @location = location
    @transport = transport
    @type = type
    @pub_id = pub_id
    @open = open

  @parse: (checkout) ->
    res = new FVSCheckout null, checkout.date_leave, checkout.date_return, checkout.time_leave, checkout.time_return, checkout.location, checkout.transport, checkout.type, checkout.pub_id, checkout.open
    res.student = FVSCard.dataManager.findStudent checkout.student_id
    res

class FVSParietal

  constructor: (guest, host, timeIn, timeOut, date) ->
    @guest = guest
    @host = host
    @timeIn = timeIn
    @timeOut = timeOut
    @date = date

    @open = true

  @parse: (object) ->
    res = new FVSParietal null,null,null,null,null
    res.pub_id = object.pub_id
    res.guest = FVSCard.dataManager.findStudent object.visitor_id
    res.host = FVSCard.dataManager.findStudent object.host_id
    res.timeIn = object.time_start
    res.timeOut = object.time_end
    res.date = object.date

    res.open = object.open
    res

class FVSList
  constructor: (ui, name) ->
    @ui = ui
    @name = name
    @items = []
    @allowRemovals = false
    @mini = false

  addAll: (items) ->
    for item in items
      @addItemToList item

  findItem: (item) ->
    for i in @items
      return i if i is item

  setAllowRemovals: (allowRemovals) ->
    @allowRemovals = allowRemovals

  addItemToList: (item) ->
    @items.push item

  pushItemToList: (item) ->
    @items.unshift item

  removeItemFromList: (item) ->
    for i in [0...@items.length]
      if item is @items[i]
        @items.splice i,1

  clearList: ->
    @items = []

  render: ->


class FVSParietalList extends FVSList

  constructor: (ui, name) ->
    super ui, name

  removeItemFromList: (item) ->
    for i in [0...@items.length]
      if @items[i]? and item.pub_id is @items[i].pub_id
        @items.splice i,1

  findItem: (id) ->
    for i in @items
      if i.pub_id is id
        return i

  render: ->
    renderedList = []
    for parietal in @items
      do (parietal) =>
        currentStatus = if parietal.open then OpenClosedStatus[0] else OpenClosedStatus[1]
        itemTemplate = $ @ui.parietalItem
        itemTemplate.click =>
          itemTemplate.attr "tabindex", "-1"
        itemTemplate.keydown (event) =>
          event.preventDefault()
          if event.which is 8
            @ui.showConfirmDialog ->
              FVSCard.dataManager.submitRemoveParietal parietal
        itemTemplate.find(".student-going").append @ui.createStudentIconView parietal.guest
        itemTemplate.find(".student-to").append @ui.createStudentIconView parietal.host
        itemTemplate.find(".p-time-start .float-label").append $ "<span style=\"font-weight: normal;\">#{parietal.timeIn}</span>"
        itemTemplate.find(".p-time-end .float-label").append $ "<span style=\"font-weight: normal;\">#{if parietal.timeOut? then parietal.timeOut else "Ongoing"}</span>"
        itemTemplate.find(".p-date").text moment(parietal.date).format("l")

        $statusView = itemTemplate.find(".status")
        $statusView.click (event)=>
          $(event.target).replaceWith @ui.generateSwitchPill parietal, OpenClosedStatus, (object, status) =>
            if status.id is 1
              FVSCard.ui.showTimepickerPopup "Select a time", (time)=>
                FVSCard.dataManager.submitUpdateParietal parietal.pub_id, status, time

            else
              FVSCard.dataManager.submitUpdateParietal parietal.pub_id, status

        $statusView
          .text(currentStatus.text)
          .css("background", currentStatus.bgcolor)
        itemTemplate.find(".p-status-container").append $statusView
        renderedList.push itemTemplate
    renderedList

class FVSCheckoutList extends FVSList

  constructor: (ui,name) ->
    super ui,name

  removeItemFromList: (item) ->
    for i in [0...@items.length]
      if @items[i]? and @items[i].pub_id is item.pub_id
        @items.splice i, 1

  findItem: (id) ->
    for i in @items
      if i.pub_id is id
        return i

  render: ->
    renderedList = []
    for item in @items
      do (item) =>
        currentStatus = if item.open then OpenClosedStatus[0] else OpenClosedStatus[1]
        itemTemplate = $ @ui.dxwxItem
        itemTemplate.click =>
          itemTemplate.attr "tabindex", "-1"
        itemTemplate.keydown (event) =>
          event.preventDefault()
          if event.which is 8
            @ui.showConfirmDialog ->
              FVSCard.dataManager.submitRemoveCheckout item
        itemTemplate.find(".c-student").append @ui.createStudentIconView item.student
        itemTemplate.find(".dxwx-type").append $ "<span>#{item.type}</span>"
        itemTemplate.find(".dxwx-date-leave").append $ "<span class=\"dxwx-detail-info\">#{moment(item.date_leave).format "MMM Do YYYY"}</span>"
        itemTemplate.find(".dxwx-date-return").append $ "<span class=\"dxwx-detail-info\">#{moment(item.date_return).format "MMM Do YYYY"}</span>"
        itemTemplate.find(".dxwx-time-leave").append $ "<span class=\"dxwx-detail-info\">#{item.time_leave}</span>"
        itemTemplate.find(".dxwx-time-return").append $ "<span class=\"dxwx-detail-info\">#{item.time_return}</span>"
        itemTemplate.find(".dxwx-location").append $ "<span class=\"dxwx-detail-info\">#{item.location}</span>"
        itemTemplate.find(".dxwx-transport").append $ "<span class=\"dxwx-detail-info\">#{item.transport}</span>"
        $statusView = itemTemplate.find(".status")
        $statusView.click (event)=>
          $(event.target).replaceWith @ui.generateSwitchPill item, OpenClosedStatus, (object, status) =>
            if status.id is 1
              FVSCard.dataManager.submitUpdateCheckout item.pub_id, status
            else
              FVSCard.dataManager.submitUpdateCheckout item.pub_id, status

        $statusView
          .text(currentStatus.text)
          .css("background", currentStatus.bgcolor)
        itemTemplate.find(".p-status-container").append $statusView

        renderedList.push itemTemplate
    renderedList

class FVSStudentList extends FVSList
  studentListSelector: ".list-container .student-list"

  constructor: (ui, name) ->
    super ui, name
    @buttons = []

  removeItemFromList: (item) ->
    for i in [0...@items.length]
      if item instanceof String
        if @items[i].firstName is item or @items[i].lastName is item
          @items.splice i, 1
      else
        if @items[i] is item
          @items.splice i, 1

  addButton: ($button) ->
    @buttons.push $button

  addButtons: (buttons) ->
    @buttons.push.apply @buttons, buttons

  clearButtons: ->
    @buttons = []

  setActionButtonEnabled: (enabled) ->
    @enableActionButton = enabled

  setPermissionsHintEnabled: (enabled) ->
    @permissionsHintEnabled = enabled

  render: ->
    renderedList = []
    for student in @items
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
          if @buttonless
            itemTemplate.find(".button-container-side").remove()
            itemTemplate.find(".pane-info").css "width", "60%"
          else
            for button in @buttons
              itemTemplate.find(".button-container-side").append button
            if @enableActionButton
              $actionButton = itemTemplate.find(".action-button")
              $actionButton.click =>
                @ui.listAction(student)
              $actionButton.mouseenter =>
                itemTemplate.css "background", "#FFF1D6"
              $actionButton.mouseleave =>
                itemTemplate.css "background", "#fff"
              $actionButton.show()
              if @permissionHintEnabled
                $actionButton.tooltip
                  content: =>
                    @ui.createPermissionsHint student
                  disabled: false
              else
                $actionButton.tooltip
                  disabled: true
            else
              itemTemplate.find(".action-button").hide()

          itemTemplate
            .find(".pane-info .student-indicator")
            .css("color", student.status.bgcolor)

        $name.text student.firstName+" \""+student.nickname+ "\" "+student.lastName+" '"+student.year.substring(2)
        $dorm.text ( if student.dorm is "DAY" then "Day Student" else student.dorm )+" "+(if student.room? then student.room else "")

        $closeButton = itemTemplate.find(".button-close")

        if @allowRemovals
          $closeButton.click =>
            @removeItemFromList student
            @ui.tabPane.updateListData()
            @onRemove student
        else
          $closeButton.css "display", "none"

        renderedList.push itemTemplate
    renderedList

class FVSCardDataManager

  constructor: (data, request) ->
    @students = []
    @lists = []
    @request = request
    for student in data.students
      @students.push new FVSStudent student.firstName, student.lastName, student.nickname, student.year, student.dorm,student.room, student.card_id, student.pub_id

    @socket = io.connect "http://localhost"
    @socket.on "session update", @sessionUpdate
    @socket.on "update student", @updateStudentStatus
    @socket.on "add checkin", @addEligableToCheckin
    @socket.on "session created", @sessionCreated
    @socket.on "remove checkin", @removeEligableToCheckin
    @socket.on "reader update", @readerUpdate
    @socket.on "reader bind", @readerBind
    @socket.on "board update", @boardUpdate
    @socket.on "reader disconnected", @readerDisconnected
    @socket.on "parietal added", @parietalAdd
    @socket.on "parietal removed", @parietalRemoved
    @socket.on "parietal update", @parietalUpdate
    @socket.on "checkout added", @checkoutAdd
    @socket.on "checkout removed", @checkoutRemove
    @socket.on "checkout update", @checkoutUpdate
    @socket.on "card swipe", @cardSwipe

  setUI: (ui)->
    @ui = ui

  registerList: (name, list) ->
    @lists.push list
    list

  createList: (name,students, clazz) ->
    unless clazz?
      clazz = FVSStudentList
    list = new clazz @ui,name
    list.addAll students
    @registerList name, list
    list

  removeList: (name) ->
    for i in [0...@lists.length]
      if @lists[i].name is name
        @lists.splice i,1
        return

  addToList: (name, item, toStart) ->
    list = @findList name
    if list?
      if toStart
        list.pushItemToList item
      else
        list.addItemToList item

  removeFromList: (name, item) ->
    list = @findList name
    if list?
      list.removeItemFromList item

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
    if data.success
      @ui.sideContainerRight.readerBound data.data
    else
      @ui.sideContainerRight.showReaderError data.data

  readerDisconnected: =>
    @ui.sideContainerRight.readerUnbound()

  inList: (student,name) ->
    list = @findList name
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

  submitGetPermissions: (student, callback) =>
    @request
      command: "get-permissions"
      student_id: student.pub_id
    , "GET", (response) =>
      if not response.success and response.data?
        @ui.showErrorMessage "Error", response.data
      else if response.data?
        callback response.data

  submitCreateSession: (tod, custom, date, dorm)=>
    mDate = moment date,"MM/DD/YYYY"
    @request
      command: "create-session"
      boardId: @board.pub_id
      type: tod
      custom: custom
      date: mDate.toDate()
      dorm: dorm
    , "GET", (response) =>
      if not response.success and response.data?
        @ui.showMessageDialog "Error",response.data
      else if response.data?
        @submitLoadSession response.data.type,moment(response.data.date).format "MM/DD/YYYY"

  submitCreateCheckout: (checkout) ->
    console.log checkout
    @request
      command: "create-checkout"
      boardId: @board.pub_id
      date_leave: checkout.date_leave
      date_return: checkout.date_return
      time_return: checkout.time_return
      transport: checkout.transport
      location: checkout.location
      student_id: checkout.student.pub_id
      type: checkout.type
      open: checkout.open
    , "GET", (response) =>
      if not response.success and response.data?
        @ui.showMessageDialog "Error", response.data

  submitRemoveCheckout: (checkout) ->
    @request
      command: "remove-checkout"
      pub_id: checkout.pub_id
    , "GET", (response) ->
      if not response.success and response.data?
        @ui.showMessageDialog "Error", response.data

  submitCreateParietal: (parietal) ->
    @request
      command: "create-parietal"
      boardId: @board.pub_id
      date: parietal.date
      host: parietal.host.pub_id
      guest: parietal.guest.pub_id
      timeStart: parietal.timeIn
      open: parietal.open
    , "GET", (response) =>
      if not response.success and response.data?
        @ui.showMessageDialog "Error", response.data

  submitRemoveParietal: (parietal) ->
    @request
      command: "remove-parietal"
      pub_id: parietal.pub_id
    , "GET", (response) =>
      if not response.success and response.data?
        @ui.showMessageDialog "Error", response.data

  submitUpdateParietal: (id, status, time) ->
    @request
      command: "update-parietal-status"
      pub_id: id
      open: status.name is "open"
      time_end: time
    , "GET", (response) =>
      if not response.success and response.data?
        @ui.showMessageDialog "Error", response.data
      else if response.data is null
        @ui.tabPane.updateListData()

  submitUpdateCheckout: (id, status) ->
    @request
      command: "update-checkout-status"
      pub_id: id
      open: status.name is "open"
    , "GET", (response) =>
      if not response.success and response.data?
        @ui.showMessageDialog "Error", response.data
      else if response.data is null
        @ui.tabPane.updateListData()

  flipStateAndSubmit: =>
    @submitUpdateSession !@session.open

  flipBoardStateAndSubmit: =>
    @submitUpdateBoard !@board.open

  submitUpdateSession: (state)=>
    if @session?
      @request
        boardId: @board.pub_id
        command: "update-session-state"
        sessionId: @session.pub_id
        open: state
      , "GET", (response) ->
        if not response.success and response.data?
          @ui.showMessageDialog "Error",response.data

  submitUpdateBoard: (state) =>
    if @board?
      @request
        command: "update-board-state"
        boardId: @board.pub_id
        open: state
      , "GET", (response) ->
        if not response.success and response.data?
          @ui.showMessageDialog "Error", response.data

  submitEligableCheckin: (student, eligable)=>
    if @session?
      @request
        command: "#{if eligable then "add" else "remove"}-tocheckin"
        student_id: student.pub_id
        checkin_id: @session.pub_id
      , "GET", (response) =>
        if not response.success and response.data?
          @ui.showMessageDialog "Error",response.data.message

  submitLoadSession: (tod, date, pub_id) =>
    mDate = moment date,"MM/DD/YYYY"
    console.log date
    console.log tod
    @request
      boardId: @board.pub_id
      command: "load-session-data"
      pub_id: pub_id if pub_id?
      date: mDate.toDate() if date?
      type: tod if tod?
    , "GET", (response) =>
      if not response.success and response.data?
        @ui.showMessageDialog "Error",response.data
      else if response.data?
        @enterSession response.data

  submitGetPermissions: (student, callback) =>
    @request
      student_id: student.pub_id
    , "GET", (response) =>
      if not response.success and response.data?
        @ui.showMessageDialog "Error", response.data
      else if response.data?
        callback response.data

  submitLoadParietals: =>
    unless @board?
      throw new Error "No board loaded"
    @request
      command: "load-parietals"
      boardId: @board.pub_id
    , "GET", (response) =>
      if not response.success and response.data?
        @ui.showMessageDialog "Error", response.data
      else if response.data?
        for parietal in response.data
          @parietalAdd parietal

  submitLoadCheckouts: =>
    unless @board?
      throw new Error "No board loaded"
    @request
      command: "load-checkouts"
      boardId: @board.pub_id
    , "GET", (response) =>
      if not response.success and response.data?
        @ui.showMessageDialog "Error", response.data
      else if response.data?
        for checkout in response.data
          @checkoutAdd checkout
        @ui.tabPane.updateListData()

  submitLoadBoard: (date) =>
    mDate = moment date, "MM/DD/YYYY"
    @request
      command: "load-weekend-board"
      date: mDate.toDate()
    , "GET", (response) =>
      if not response.success and response.data?
        @ui.showMessageDialog "Error", response.data
      else if response.data?
        @enterBoard response.data

  getSessionList: (callback)=>
    if @board?
      @request
        command: "load-sessions-for-board"
        boardId: @board.pub_id
      , "GET", (response) =>
        if not response.success and response.data?
          @ui.showMessageDialog "Error", response.data
        else if response.data?
          callback response.data

  sessionCreated: (session) =>
    if @board?
      @ui.tabPane.tabScreenMap[1].addSessionEntry session

  submitCreateBoard: (date) =>
    mDate = moment date, "MM/DD/YYYY"
    @request
      command: "create-weekend-board"
      date: mDate.toDate()
    , "GET", (response) =>
      if not response.success and response.data?
        @ui.showMessageDialog "Error", response.data
      else if response.data?
        @enterBoard response.data

  beginCreateSession: =>
    @ui.showSessionInfoPopup "Create Session", @submitCreateSession

  beginFlipSessionStatus: =>
    @ui.showConfirmDialog @flipStateAndSubmit

  beginFlipBoardStatus: =>
    @ui.showConfirmDialog @flipBoardStateAndSubmit

  beginLoadSession: =>
    @ui.showSessionInfoPopup "Load Session",@submitLoadSession

  beginCreateBoard: =>
    @ui.showBoardInfoPopup "Create New Weekend Board", @submitCreateBoard

  beginLoadBoard: =>
    @ui.showBoardInfoPopup "Load Weekend Board", @submitLoadBoard

  beginExitSession: =>
    @ui.showConfirmDialog @exitSession

  beginExitBoard: =>
    @ui.showConfirmDialog @exitBoard

  enterSession: (res) =>
    @session = res.session
    console.log @session.dorm
    toCheckin = @findList "Absent"
    toCheckin.setAllowRemovals true
    toCheckin.onRemove = (student) =>
      @submitEligableCheckin student, false

    for status in res.students
      student = @findStudent status.student_id
      student.setStatusById status.status
      student.eligableForCheckin = true
      @addToList "Absent", student, false
      @sessionSort student
    @ui.tabPane.triggerUpdate()
    $.cookie "session-loaded", @session.pub_id

  enterBoard: (res) =>
    @board = res
    @ui.menuBar.enterWeekendBoard @board
    #TODO
    $.cookie "board-loaded", @board.pub_id

  exitBoard: =>
    @board = null
    @exitSession()
    @ui.menuBar.exitWeekendBoard()
    @ui.tabPane.resetScreens()
    @resetBoardLists()
    $.removeCookie "board-loaded"

  resetBoardLists: =>
    @findList("Ongoing")?.clearList()
    @findList("Past")?.clearList()
    @findList("Returned")?.clearList()
    @findList("Off Campus")?.clearList()

  sessionSort: (student)=>
    if @session?
      if student.status.id is 1
        #TODO
        @removeFromList "Absent", student
        @removeFromList "Checked In", student
        @addToList "Absent", student, true
      else
        #TODO
        @removeFromList "Checked In", student
        @removeFromList "Absent", student
        @addToList "Checked In", student, true

  checkoutAdd: (checkout) =>
    if checkout?
      if @board and @board.pub_id is checkout.board_id
        res = FVSCheckout.parse checkout
        console.log res
        if res.open
          @addToList "Off Campus", res
        else
          @addToList "Returned", res
        @ui.tabPane.updateListData(open)

  checkoutRemove: (checkout) =>
    if checkout?
      if @board? and @board.pub_id is checkout.board_id
        console.log "BUtts"
        res = FVSCheckout.parse checkout
        console.log res
        @removeFromList "Off Campus", res
        @removeFromList "Returned", res
        @ui.tabPane.updateListData()

  parietalAdd: (parietal) =>
    if parietal?
      if @board? and @board.pub_id is parietal.board_id
        res = FVSParietal.parse parietal
        if res.open
          @addToList "Ongoing",res
        else
          @addToList "Past", res
        @ui.tabPane.updateListData()

  parietalRemoved: (parietal) =>
    if parietal?
      if @board? and @board.pub_id is parietal.board_id
        res = FVSParietal.parse parietal
        @removeFromList "Ongoing", res
        @removeFromList "Past", res
        @ui.tabPane.updateListData()

  parietalUpdate: (parietal) =>
    if @board? and @board.pub_id is parietal.board_id
      currentParietal = @findList("Ongoing").findItem parietal.pub_id
      unless currentParietal?
        currentParietal = @findList("Past").findItem parietal.pub_id
      currentParietal.open = parietal.open
      currentParietal.timeOut = parietal.time_end
      @removeFromList "Past", currentParietal
      @removeFromList "Ongoing",currentParietal
      if currentParietal.open
        @addToList "Ongoing", currentParietal
      else
        @addToList "Past", currentParietal
      @ui.tabPane.updateListData()

  checkoutUpdate: (checkout) =>
    if @board? and @board.pub_id is checkout.board_id
      currentCheckout = @findList("Off Campus").findItem checkout.pub_id
      unless currentCheckout?
        currentCheckout = @findList("Returned").findItem checkout.pub_id
      currentCheckout.open = checkout.open
      @removeFromList "Off Campus", currentCheckout
      @removeFromList "Returned", currentCheckout
      if currentCheckout.open
        @addToList "Off Campus", currentCheckout
      else
        @addToList "Returned", currentCheckout
      @ui.tabPane.updateListData()

  cardSwipe: (res)=>
    unless res.success
      console.log res.data
    else
      student = @findStudent res.data.student.pub_id
      @ui.listAction student if @ui.listAction?

  exitSession: =>
    @session = null
    @ui.tabPane.screen.currentIndex = 0
    @removeList "Checked In"
    @removeList "Absent"
    @ui.tabPane.reset()
    @resetStudents()
    @ui.tabPane.triggerUpdate()
    $.removeCookie "session-loaded"

  addEligableToCheckin: (status) =>
    if @session? and @session.pub_id is status.checkin_id
      student = @findStudent status.student_id
      unless student.eligableForCheckin
        student.eligableForCheckin = true
        @addToList "Absent", student, true
        @ui.tabPane.updateListData()

  removeEligableToCheckin: (status) =>
    if @session? and @session.pub_id is status.checkin_id
      student = @findStudent status.student_id
      if student.eligableForCheckin
        student.eligableForCheckin = false
        @removeFromList "Absent", student
        @ui.tabPane.updateListData()

  sessionUpdate: (session) =>
    if @session? and @session.pub_id is session.pub_id
      @session.open = session.open
      @ui.update()

  boardUpdate: (board) =>
    if @board? and @board.pub_id is board.pub_id
      @board.open = board.open
      @ui.update()

  updateStudentStatus: (status) =>
    if @session? and @session.pub_id is status.checkin_id
      student = @findStudent status.student_id
      if student?
        student.setStatusById status.state
        @sessionSort student
        @ui.tabPane.updateListData()

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
      @ui.tabPane.updateListData()

  class FVSCard

    constructor: (request, uiData, data) ->
      @fvsCardRequest = request
      @state = BoardStatus.notInBoard

      @dataManager = new FVSCardDataManager data, request
      @ui = new FVSCardUI uiData, @dataManager
      @dataManager.setUI @ui

      allStudents = @dataManager.createList "All Students", @dataManager.students
      day = @dataManager.createList "Day", []
      bList = @dataManager.createList "Boarding", []
      for student in @dataManager.students
        if student.dorm is "DAY"
          @dataManager.addToList "Day", student, false
        else
          @dataManager.addToList "Boarding", student, false
      @ui.studentList.screen.addDisplayList allStudents
      @ui.studentList.screen.addDisplayList day
      @ui.studentList.screen.addDisplayList bList
      @ui.studentList.screen.setDisplayList "All Students"
      @dataManager.updateUi()

      @ui.menuBar.exitWeekendBoard()
      @ui.sideContainerRight.readerUnbound()
      #@ui.tabPane.screen.setDisplayList "All Students"

  window.FVSCard =
    init: (request, ui, data) ->
      window.FVSCard = new FVSCard request, ui, data
