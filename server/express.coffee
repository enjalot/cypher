express = require 'express'

expressSession = require 'express-session'
serveStatic = require 'serve-static'
favicon = require 'serve-favicon'
compression = require 'compression'
cookieParser = require 'cookie-parser'
bodyParser = require 'body-parser'
highway = require 'racer-highway'
derbyLogin = require 'derby-login'


module.exports = (store, apps, error, publicDir) ->

  connectStore = require('connect-mongo')(expressSession)
  
  if process.env.MONGO_PORT
    # weird thing for deploying for now
    mongoURL = process.env.MONGO_PORT.replace('tcp', 'mongodb') + "/#{process.env.MONGO_DB}" 
  else if process.env.MONGO_URL
    mongoURL = process.env.MONGO_URL
  sessionStore = new connectStore url: mongoURL

  session = expressSession
    secret: process.env.SESSION_SECRET
    store: sessionStore
    cookie: process.env.SESSION_COOKIE
    saveUninitialized: true
    resave: true


  handlers = highway store, session: session

  expressApp = express()
    .use favicon publicDir + '/img/favicon.ico'
    .use compression()
    .use serveStatic publicDir
    .use store.modelMiddleware()
    .use cookieParser()
    .use bodyParser.json()
    .use bodyParser.urlencoded extended: true
    .use session
    .use derbyLogin.middleware store, require '../config/login'
    .use handlers.middleware

    # static files for codemirror
    node_modules = __dirname + '/../node_modules/'
    cm = node_modules + "d-codemirror/node_modules/codemirror/"
    showdown = node_modules + "d-showdown/node_modules/showdown/compressed"

    expressApp.use('/showdown', express.static(showdown));
    expressApp.use('/cm', express.static(cm));

  apps.forEach (app) -> expressApp.use app.router()

  expressApp.use require './routes'

  expressApp
    .all '*', (req, res, next) -> next '404: ' + req.url
    .use error

  {expressApp:expressApp, upgrade:handlers.upgrade}

