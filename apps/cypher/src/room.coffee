app = require '../'

app.get '/:room', (page, model, {room}, next) ->
  return page.redirect '/lobby' unless room && /^[a-zA-Z0-9_-]+$/.test room
  model.set '_page.room', room

  roomQuery = model.at "rooms.#{room}"
  cypherQuery = model.query 'cyphers',
    room: room

  model.subscribe roomQuery, cypherQuery, ->
    if !cypherQuery.get().length
      cypher = model.add "cyphers", {
        room: room
        code:
          js: 'console.log("hi")'
          html: '<div class="custom">cool</div>'
          css: '.custom { border: 1px solid orange; }'
      }
    page.render 'room'


app.get '/:room/:cypher', (page, model, {room,cypher}, next) ->
  console.log "begin", room,cypher
  return page.redirect '/lobby' unless room && /^[a-zA-Z0-9_-]+$/.test room
  model.set '_page.room', room
  model.set '_page.cypherId', cypher
  model.ref "_page.cypher", "cyphers.#{cypher}"


  cypherQuery = model.query 'cyphers',
    _id: cypher
    room: room

  model.subscribe cypherQuery, ->
    page.render 'room:single-cypher'


class Room
  init: ->
    console.log "init"
    filter = @model.filter @model.scope("cyphers"), (cypher) ->
      return true
    @model.ref "cyphers", filter

  create: ->
    console.log "create"


app.component 'room', Room

class SingleCypher
  init: ->
    console.log "sc init"

    ###
    @model.ref @model.scope("cyphers.#{cypherId}")
    @model.start "cypher", @model.scope("cyphers"), (cyphers) ->
      for id,cypher of cyphers when cypher
        return cypher
    ###

  create: ->
    console.log "sc create"


app.component 'room:single-cypher', SingleCypher