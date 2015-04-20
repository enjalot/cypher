liveDbMongo = require 'livedb-mongo'
coffeeify = require 'coffeeify'

module.exports = (derby, publicDir) ->

  console.log "PROCESS.ENV", process.env

  if process.env.REDIS_HOST
    process.env.REDIS_URL = "redis://#{REDIS_HOST}:#{REDIS_PORT}"

  mongoURL = "mongodb://" + 
    (process.env.MONGO_HOST || 'localhost') + ':' +
    (process.env.MONGO_PORT || 27017) + '/' + 
    process.env.MONGO_DB
  console.log "url", mongoURL

  mongo = liveDbMongo mongoURL + '?auto_reconnect', {safe: true}

  derby.use require 'racer-bundle'

  redis = require 'redis-url'
  livedb = require 'livedb'

  redisDriver = livedb.redisDriver mongo, redis.connect(), redis.connect()

  store = derby.createStore
    backend: livedb.client driver: redisDriver, db: mongo


  store.on 'bundle', (browserify) ->

    browserify.transform {global: true}, coffeeify

    pack = browserify.pack

    browserify.pack = (opts) ->
      detectTransform = opts.globalTransform.shift()
      opts.globalTransform.push detectTransform
      pack.apply this, arguments

  store

