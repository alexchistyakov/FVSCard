express = require 'express'
router  = express.Router()

sessionHandler   = require "./sessionhandler"
inSessionHandler = require "./sessionhandler/insession"

router.get '/', sessionHandler.inputSession
router.post '/', sessionHandler.joinSession

router.get '/checkin', inSessionHandler.showSessionPage
