app = require '../'

FIFTEEN = 1000 * 60 * 15

app.get '/track/:trackId', (page, model, {trackId}, next) ->
  return page.redirect '/lobby' unless trackId && /^[a-zA-Z0-9_-]+$/.test trackId
  model.set '_page.trackId', trackId

  $track = model.at "tracks.#{trackId}"

  usersQuery = model.query "users", {}

  cypherQuery = model.query 'cyphers',
    trackId: trackId

  presenceQuery = model.query 'presence',
    trackId: trackId
    lastSeenAt: {$gt: +new Date() - FIFTEEN}

  model.subscribe $track, cypherQuery, presenceQuery, usersQuery, ->
    if !$track.get()
      model.add "tracks",
        _id: trackId
        name: "just another track"
        userId: model.get "_session.user.id"
        createdAt: new Date()

    if !cypherQuery.get().length and model.get "_session.loggedIn"
      cypherId = model.add "cyphers", {
        trackId: trackId
        userId: model.get "_session.user.id"
        name: "mic check"
        code:
          js: 'console.log("hi", data)'
          html: '<div class="custom">through the lights camera action glamour glitter and gold</div>'
          css: '.custom { color: #050505 }'
      }
      model.ref "_page.cypher", model.at "cyphers.#{cypherId}"

    if cypherQuery.get().length == 1
      cypherId = cypherQuery.get()[0]?.id
      console.log "cypher id11", cypherId
      model.ref "_page.cypher", model.at "cyphers.#{cypherId}"

    page.render 'track'



class Track
  init: ->
    @track = @model.at "track"
    @cyphers = @model.at "cyphers"
    @primary = @model.at "primary"
    @preview = @model.at "preview"
    @selectedTab = @model.at "selectedTab"
    @selectedTab.setNull "primary"
    filter = @model.filter @model.scope("cyphers"), (cypher) ->
      return true
    @model.ref "cyphers", filter
    trackId = @model.root.get "_page.trackId"
    @model.ref "track", @model.scope("tracks.#{trackId}")
    @track.setNull "md", ""
    @model.set "dataTypes", ["csv", "json"]
    @preview.setNull @track.get("data.text") or ""

    if primaryId = @model.get "track.primaryId"
      @model.ref "primary", @model.scope("cyphers.#{primaryId}")
    @model.on "change", "track.primaryId", (primaryId) =>
      @model.ref "primary", @model.scope("cyphers.#{primaryId}")
    if !primaryId and cypherId = @cyphers.get()?[0]?.id
      @model.set "track.primaryId", cypherId


  create: ->
    console.log "create"

  makePrimary: (cypher) ->
    @model.set "track.primaryId", cypher.id if cypher?.id

  trackIsMine: ->
    return @model.get("track.userId") == @model.root.get("_session.userId")

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
    return false unless session.user?.id == @model.get("track.userId")
    return true

  edit: (thing) ->
    return unless @canEdit()
    editing = !@model.get "editing.#{thing}"
    @model.set "editing.#{thing}", editing

  save: (thing) ->
    return unless @canEdit()
    @track.set "data.text", @preview.get()
    @model.set "editing.#{thing}", false



app.component 'track', Track
