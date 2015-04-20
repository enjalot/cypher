module.exports = class Cypher
  view: __dirname
  style: __dirname
  name: 'cypher'
  init: ->
    @cypher = @model.at "cypher"
    @styles = @model.at "cypher.styles"
    @styles.setNull []
    @libs = @model.at "cypher.libs"
    @libs.setNull []
    @readOnly = @model.at "readOnly"
    userId = @model.root.get("_session.userId")
    authorId = @cypher.get("user.id")
    console.log authorId != userId, authorId, userId
    @readOnly.set authorId != userId

  create: ->

  addStyle: ->
    @styles.push "https://"

  addLib: ->
    @libs.push "https://"

  forkCypher: (cypher) ->
    return unless @model.root.get("_session.loggedIn")
    user = @model.root.get("_session.user")
    return unless user
    copy = @model.root.getDeepCopy("cyphers.#{cypher.id}")
    delete copy.id
    copy.user =
      id: user.id
      name: user.github?.username

    console.log "copy", copy
    copyId = @model.root.add "cyphers", copy
    @app.history.push "/room/#{copy.room}/#{copyId}"


