MODES = 
  "js": "javascript"
  "html":"htmlmixed"
  "css":"css"

module.exports = class CodeEditor
  view: __dirname

  init: () ->
    @code = @model.at "code"
    @tabs = @model.at "tabs"
    @tabs.set Object.keys(@code.get() or {})
    @active = @model.at "active"
    @active.setNull @tabs.get()[0]

  create: () ->

  select: (tab) ->
    @active.set tab

  getMode: (active) ->
    return MODES[active]