app = require '../'

FIFTEEN = 1000 * 60 * 15

app.get '/room/:roomId', (page, model, {roomId}, next) ->
  return page.redirect '/lobby' unless roomId && /^[a-zA-Z0-9_-]+$/.test roomId
  model.set '_page.roomId', roomId

  $room = model.at "rooms.#{roomId}"

  usersQuery = model.query "users", {}

  cypherQuery = model.query 'cyphers',
    roomId: roomId

  presenceQuery = model.query 'presence',
    roomId: roomId
    lastSeenAt: {$gt: +new Date() - FIFTEEN}

  model.subscribe $room, cypherQuery, presenceQuery, usersQuery, ->
    console.log "IN SUB", $room.get()
    if !$room.get()
      console.log "no room", roomId
      model.add "rooms",
        _id: roomId
        name: "just another room"
        userId: model.get "_session.user.id"

    if !cypherQuery.get().length and model.get "_session.loggedIn"
      console.log "no cyphers?"
      cypherId = model.add "cyphers", {
        roomId: roomId
        userId: model.get "_session.user.id"
        code:
          js: 'console.log("hi")'
          html: '<div class="custom">cool</div>'
          css: '.custom { border: 1px solid orange; }'
      }
      model.ref "_page.cypher", model.at "cyphers.#{cypherId}"

    if cypherQuery.get().length == 1
      cypherId = cypherQuery.get()[0]?.id
      console.log "cypher id11", cypherId
      model.ref "_page.cypher", model.at "cyphers.#{cypherId}"

    page.render 'room'



class Room
  init: ->
    @room = @model.at "room"
    @cyphers = @model.at "cyphers"
    @primary = @model.at "primary"
    @preview = @model.at "preview"
    @selectedTab = @model.at "selectedTab"
    @selectedTab.setNull "primary"
    filter = @model.filter @model.scope("cyphers"), (cypher) ->
      return true
    @model.ref "cyphers", filter
    roomId = @model.root.get "_page.roomId"
    @model.ref "room", @model.scope("rooms.#{roomId}")
    @room.setNull "md", ""
    @model.set "dataTypes", ["csv", "json"]
    @preview.setNull @room.get("data.text") or ""

    if primaryId = @model.get "room.primaryId"
      @model.ref "primary", @model.scope("cyphers.#{primaryId}")
    @model.on "change", "room.primaryId", (primaryId) =>
      @model.ref "primary", @model.scope("cyphers.#{primaryId}")
    if !primaryId and cypherId = @cyphers.get()?[0]?.id
      @model.set "room.primaryId", cypherId


  create: ->
    console.log "create"

  makePrimary: (cypher) ->
    @model.set "room.primaryId", cypher.id if cypher?.id

  roomIsMine: ->
    return @model.get("room.userId") == @model.root.get("_session.userId")

  selectTab: (tab) ->
    console.log "tab", tab
    @selectedTab.set tab

  canCreateCypher: ->
    session = @model.root.get("_session") or {}
    return false unless session.loggedIn
    return false unless session.user # should exist if logged in
    for cypher in @model.get("cyphers") when cypher
      return false if session.userId == cypher.user?.id
    return true

  addCypher: ->

  canEdit: ->
    session = @model.root.get("_session") or {}
    return false unless session.loggedIn
    return false unless session.user?.id == @model.get("room.userId")
    return true

  edit: (thing) ->
    return unless @canEdit()
    editing = !@model.get "editing.#{thing}"
    @model.set "editing.#{thing}", editing

  save: (thing) ->
    return unless @canEdit()
    @room.set "data.text", @preview.get()
    @model.set "editing.#{thing}", false



app.component 'room', Room
