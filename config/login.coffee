###
this should be a file like:
module.exports = {
  clientID: "XXX",
  clientSecret: "XXX"
}
you can create a github dev app:
https://github.com/settings/applications
###
github = require("./github") or {}

module.exports =
  # db collection
  collection: 'auths'
  # projection of db collection
  publicCollection: 'users'
  user:
    id: true
    email: true
    github: true
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
      conf: github
  hooks:
    request: (req, res, userId, isAuthenticated, done) -> done()
