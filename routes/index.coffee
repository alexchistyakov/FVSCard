inSessionHandler = require "./sessionhandler"
authPage         = require "./auth"
authHandler      = require "./auth/authentication"
api              = require "./api"

module.exports = (app)->
  app.get '/', inSessionHandler.verifyAuthAndRedirect

  app.get  '/login', authPage.loginPage
  app.post '/login', authHandler.authenticateLogin

  app.get '/checkin', inSessionHandler.showSessionPage

  app.get '/api', api.express
  app.post '/api', api.express

