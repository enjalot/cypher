liveDbMongo = require 'livedb-mongo'
coffeeify = require 'coffeeify'

module.exports = (derby, publicDir) ->
  if process.env.REDIS_PORT
    process.env.REDIS_URL = process.env.REDIS_PORT.replace('tcp', 'redis')
  if process.env.MONGO_PORT
    # weird thing for deploying for now
    mongoURL = process.env.MONGO_PORT.replace('tcp', 'mongodb') + "/#{process.env.MONGO_DB}" 
  else if process.env.MONGO_URL
    mongoURL = process.env.MONGO_URL
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

