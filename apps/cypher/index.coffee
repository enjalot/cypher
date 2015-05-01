derby = require 'derby'

app = module.exports = derby.createApp 'cypher', __filename


app.use require 'derby-login/components'
app.use require 'derby-debug'
app.serverUse module, 'derby-stylus'
app.serverUse module, 'derby-markdown'

app.component require 'd-codemirror'
app.component require 'd-showdown'
app.component require('../../components/code-editor')
app.component require('../../components/code-renderer')

app.loadViews __dirname + '/views'
app.loadStyles __dirname + '/styles'

app.get '*', (page, model, params, next) ->
  if model.get '_session.loggedIn'
    userId = model.get '_session.userId'
    $user = model.at "users.#{userId}"
    model.subscribe $user, ->
      model.ref '_session.user', $user
      next()
  else
    next()


app.get '/', (page, model) ->

  trackQuery = model.query 'tracks', {$limit: 20}
  userQuery = model.query 'users', {}
  model.subscribe trackQuery, userQuery, ->
    trackQuery.ref "_page.tracks"
    page.render 'home'

app.get '/login', (page) ->
  page.render 'login'

app.get '/register', (page) ->
  page.render 'register'

app.proto.addRoom = () ->
  model = app.model
  return unless model.get "_session.loggedIn"
  console.log "adding track"
  model.add "tracks",
    name: "just another track"
    md: "# my track"
    data:
      text: "{answer: 42}"
      type: "json"
    userId: model.get "_session.user.id"



require './src/track'
require './src/cypher'