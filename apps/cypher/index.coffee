derby = require 'derby'

app = module.exports = derby.createApp 'cypher', __filename


app.use require 'derby-login/components'
app.use require 'derby-debug'
app.serverUse module, 'derby-stylus'
app.serverUse module, 'derby-markdown'

app.component require 'd-codemirror'
app.component require('../../components/code-editor')
app.component require('../../components/code-renderer')
app.component require('../../components/cypher')

app.loadViews __dirname + '/views'
app.loadStyles __dirname + '/styles'

app.get '/', (page, model) ->
  page.render 'home'

app.get '/login', (page) ->
  page.render 'login'

app.get '/register', (page) ->
  page.render 'register'


require './src/room'