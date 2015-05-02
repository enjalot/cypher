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
    @presences = @model.at "presences"

  create: () ->

    listenToCursor = (active) =>
      cm = @editor.cm
      debounce = null
      cm.on "cursorActivity", (cm) =>
        if debounce
          clearTimeout(debounce);
          debounce = null;
        debounce = setTimeout =>
          @emit "cursor", active, cm.getCursor()
        , 150

    @active.on "change", listenToCursor
    listenToCursor @active.get()

    handleCursor = (index, pos) =>
      return unless pos
      presence = @presences.get(index)
      return unless presence
      return unless presence.tab == @active.get()
      setTimeout =>
        widget = document.getElementById "cursor-#{presence?.id}"
        return unless widget
        @editor.cm.addWidget pos, widget
      , 100

    @presences.on "change", "*.cursor", handleCursor.bind(@)
    @presences.on "change", "*.tab", (index) =>
      handleCursor index, @presences.get("#{index}.cursor")

    @model.on "change", "showCursors", =>
      for cursor,i in (@presences.get() or []) when cursor
        handleCursor(i, cursor.cursor)

  select: (tab) ->
    @active.set tab

  getMode: (active) ->
    return MODES[active]