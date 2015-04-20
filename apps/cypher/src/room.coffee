app = require '../'

app.get '/room/:room', (page, model, {room}, next) ->
  return page.redirect '/lobby' unless room && /^[a-zA-Z0-9_-]+$/.test room
  model.set '_page.room', room

  $room = model.at "rooms.#{room}"

  cypherQuery = model.query 'cyphers',
    room: room

  model.subscribe $room, cypherQuery, ->
    if !$room.get()
      $room.set
        name: "just another room"
        user:
          id: model.get "_session.user.id"
          name: model.get "_session.user.github.username"

    if !cypherQuery.get().length and model.get "_session.loggedIn"
      cypherId = model.add "cyphers", {
        room: room
        user:
          id: model.get "_session.user.id"
          name: model.get "_session.user.github.username"
        code:
          js: 'console.log("hi")'
          html: '<div class="custom">cool</div>'
          css: '.custom { border: 1px solid orange; }'
      }
      model.ref "_page.cypher", model.at "cyphers.#{cypherId}"

    if cypherQuery.get().length == 1
      cypherId = cypherQuery.get()[0]?.id
      model.ref "_page.cypher", model.at "cyphers.#{cypherId}"

    page.render 'room'


app.get '/room/:room/:cypher', (page, model, {room,cypher}, next) ->
  return page.redirect '/lobby' unless room && /^[a-zA-Z0-9_-]+$/.test room
  model.set '_page.room', room
  model.set '_page.cypherId', cypher
  model.ref "_page.cypher", "cyphers.#{cypher}"


  cypherQuery = model.query 'cyphers',
    _id: cypher
    room: room

  model.subscribe cypherQuery, "rooms.#{room}", ->
    page.render 'room:single-cypher'


class Room
  init: ->
    console.log "init"
    filter = @model.filter @model.scope("cyphers"), (cypher) ->
      return true
    @model.ref "cyphers", filter

  create: ->
    console.log "create"

  canCreateCypher: ->
    session = @model.root.get("_session") or {}
    return false unless session.loggedIn
    return false unless session.user # should exist if logged in
    for cypher in @model.get("cyphers") when cypher
      return false if session.userId == cypher.user?.id
    return true

  addCypher: ->

app.component 'room', Room

class SingleCypher
  init: ->
    console.log "sc init"
    roomId = @model.root.get("_page.room")
    console.log "room id", roomId, @model.root.get("rooms.#{roomId}")
    @model.set "room", @model.root.get("rooms.#{roomId}")
    #@model.ref @model.scope("rooms.#{roomId}"), "room"


    ###
    @model.ref @model.scope("cyphers.#{cypherId}")
    @model.start "cypher", @model.scope("cyphers"), (cyphers) ->
      for id,cypher of cyphers when cypher
        return cypher
    ###

  create: ->
    console.log "sc create"


app.component 'room:single-cypher', SingleCypher