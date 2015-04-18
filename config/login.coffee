module.exports =
  # db collection
  collection: 'auths'
  # projection of db collection
  publicCollection: 'users'
  user:
    id: true
    email: true
  confirmRegistration: false
  # passportjs options
  passport:
    successRedirect: '/'
    failureRedirect: '/',
    registerCallback: (req, res, user, done) ->
      model = req.getModel()
      $user = model.at "auths.#{user.id}"
      model.fetch $user, ->
        $user.set 'email', $user.get('local.email'), done
  strategies:
    github:
      strategy: require("passport-github").Strategy
      conf:
        clientID: "eeb00e8fa12f5119e5e9"
        clientSecret: "61631bdef37fce808334c83f1336320846647115"
  hooks:
    request: (req, res, userId, isAuthenticated, done) -> done()