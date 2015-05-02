app = require '../'

MINUTE = 1000 * 60
ACTIVE = 5 * MINUTE

app.get '/track/:trackId/:cypherId', (page, model, {trackId,cypherId}, next) ->
  return page.redirect '/lobby' unless trackId && /^[a-zA-Z0-9_-]+$/.test trackId
  model.set '_page.trackId', trackId
  model.set '_page.cypherId', cypherId
  model.ref "_page.cypher", "cyphers.#{cypherId}"

  usersQuery = model.query "users", {}

  cypherQuery = model.query 'cyphers',
    _id: cypherId
    trackId: trackId

  userId = model.get "_session.userId"
  userPresenceQuery = model.query 'presence',
    trackId: trackId
    cypherId: cypherId
    userId: userId

  cypherPresenceQuery = model.query 'presence',
    trackId: trackId
    cypherId: cypherId

  model.subscribe usersQuery, cypherQuery, userPresenceQuery, cypherPresenceQuery, "tracks.#{trackId}", ->
    if !userPresenceQuery.get()?.length and model.get "_session.loggedIn"
      # no presence for this user yet, create one
      presenceId = model.add "presence",
        trackId: trackId
        cypherId: cypherId
        userId: userId
        lastSeenAt: +new Date
    else
      presenceId = userPresenceQuery.get()[0]?.id
    model.set "_page.presenceId", presenceId

    page.render 'cypher'

module.exports = class Cypher
  name: 'cypher'
  init: ->
    @cypher = @model.at "cypher"
    @model.ref "cypher", @model.scope("_page.cypher")
    @cypher.setNull "editors", []
    @styles = @model.at "cypher.styles"
    @styles.setNull []
    @libs = @model.at "cypher.libs"
    @libs.setNull []
    @readOnly = @model.at "readOnly"
    userId = @model.root.get("_session.userId")
    authorId = @cypher.get("userId")
    @readOnly.set authorId != userId

    @track = @model.at "track"
    @presence = @model.at "presence"

    trackId = @model.root.get("_page.trackId")
    console.log "track id", trackId, @model.root.get("tracks.#{trackId}")
    @track.set @model.root.get("tracks.#{trackId}")
    presenceId = @model.root.get("_page.presenceId")
    if presenceId
      @model.ref "presence", @model.scope("presence.#{presenceId}")

    @showCursors = @model.at "showCursors"
    @showCursors.setNull true

    # get active users
    filter = @model.filter @model.scope("presence"), (presence) -> true
    roundDown = (d) ->
      Math.floor(d/20000) * 20000
    filter.sort (a,b) ->
      #diff = roundDown(b.lastSeenAt) - roundDown(a.lastSeenAt)
      #return diff
      return a?.userId - b?.userId
    @model.ref "presences", filter


  create: ->
    # presence timeout 
    setInterval =>
      @model.set "presence.lastSeenAt", +new Date()
    , 1000

  addStyle: ->
    @styles.push "https://"

  addLib: ->
    @libs.push "https://"

  inActive: (presence) ->
    # TODO use timezones
    dt = +new Date() - presence?.lastSeenAt 
    if dt > ACTIVE
      return true
    else
      return false

  toggle: (path) ->
    @model.set path, !@model.get path

  cursorHandler: (tab, cursor) ->
    return unless @model.root.get("_session.loggedIn")
    @presence.set "tab", tab
    @presence.set "cursor", cursor
    @presence.set "lastSeenAt", +new Date

  isEditor: (presence) ->
    return false unless presence
    return true if @cypher.get("userId") == presence.userId
    editors = @cypher.get("editors") or []
    return true if editors.indexOf(presence.userId) >= 0
    return false

  canEdit: ->
    session = @model.root.get("_session") or {}
    return true if @cypher.get("hyphy")
    return false unless session.loggedIn
    return false unless session.user?.id == @cypher.get("userId")
    return true

  forkCypher: (cypher) ->
    return unless @model.root.get("_session.loggedIn")
    user = @model.root.get("_session.user")
    return unless user
    copy = @model.root.getDeepCopy("cyphers.#{cypher.id}")
    delete copy.id
    copy.userId = user.id

    copyId = @model.root.add "cyphers", copy
    @app.history.push "/track/#{copy.trackId}/#{copyId}"


app.component 'cypher', Cypher