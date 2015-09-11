express = require "express"
path = require "path"
favicon = require "serve-favicon"
logger = require "morgan"
cookieParser = require "cookie-parser"
bodyParser = require "body-parser"
session = require "express-session"
ejs = require "ejs"
passport = require "passport"
passportLocal = require "passport-local"

dbModels = require "./models"
config = require "./config"
routes = require "./routes"
authPage = require "./routes/auth"
authHandler = require "./routes/auth/authentication"
assets = require "./public"
globals = require "./routes/requestglobals.coffee"

require("./lib")()

app = express()
server = require("http").createServer app

#Declare a global reference to jquery
GLOBAL.$ = require "jquery"

# view engine setup
app.engine "html", ejs.renderFile
app.set "views", path.join __dirname, "views"
app.set "view engine", "html"
app.set "view options", layout: true
app.set "view cache", true
app.set "x-powered-by", false
# uncomment after placing your favicon in /public
#app.use(favicon(__dirname + "/public/favicon.ico"));
app.use logger "dev"
app.use cookieParser()
app.use bodyParser.urlencoded
    extended: false

app.use "/img",express.static __dirname+"/public/images"
app.use "/init",express.static __dirname+"/public/coffee/init"

assets.init app,server
app.use assets.express
app.use session
    secret: process.env.SESSION_SECRET or "devsecret"
    resave: true
    saveUninitialized: true

app.use dbModels.express

#app.use require "./test"

app.use globals.express

app.use "/", routes

# catch 404 and forward to error handler
app.use (req, res, next) ->
    err = new Error("Not Found")
    err.status = 404
    next(err)

# production error handler
if app.get("env") is "development"
    app.use (err, req, res, next) ->
        res.status err.status || 500
        res.render "error",
            message: err.message,
            error: err
        console.log err.stack
# no stacktraces leaked to user
app.use (err, req, res, next) ->
    res.status err.status || 500
    res.render "error",
        message: err.message,
        error: {}

module.exports = app

server.listen config.general.port
