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

  mongoURL = "mongodb://" + 
    (process.env.MONGO_HOST || 'localhost') + ':' +
    (process.env.MONGO_PORT || 27017) + '/' + 
    process.env.MONGO_DB
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
    node_modules = __dirname + '/../node_modules/';
    cm = node_modules + "d-codemirror/node_modules/codemirror/";
    expressApp.use('/cm', express.static(cm));

  apps.forEach (app) -> expressApp.use app.router()

  expressApp.use require './routes'

  expressApp
    .all '*', (req, res, next) -> next '404: ' + req.url
    .use error

  {expressApp:expressApp, upgrade:handlers.upgrade}

