# we build up an html page that will run inside an iframe
# it will create a derby-standalone environment with a copy of the root data
# from the current page
TEMPLATE = """

<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<script src="https://cdnjs.cloudflare.com/ajax/libs/d3/3.5.5/d3.min.js"></script>
<style id="style-parent"></style>
<style>
body {
  background-color: white
}
</style>
"""
TEMPLATEBODY = """
</head>
<body>
"""

ENDCUSTOM = "</body>"

ENDTEMPLATE =  """
<script>
console.log("iframe built")
</script>
"""

module.exports = class CodeRenderer 
  view: __dirname

  init: () ->
    @code = @model.at "code"
    @data = @model.at "data"
    @libs = @model.at "libs"
    @styles = @model.at "styles"
    @data.setNull []
    @libs.setNull []
    @styles.setNull []
    @blobUrl = @model.at "blobUrl"
    @syntaxError = @model.at "syntaxError"
    @initError = @model.at "initError"

  create: () ->
    ###
      We allow the iframe to run scripts but not access the parent.
      This means malicious user scripts 
    ###
    @inner.sandbox = "allow-scripts"

    @runCode()
    # when the code changes lets rebuild the iframe
    @code.on("change", "**", @runCode.bind(@))
    @data.on("change", "**", @runCode.bind(@))
    @libs.on("change", "**", @runCode.bind(@))
    @styles.on("change", "**", @runCode.bind(@))

  runCode: ->
    code = @code.get()
    return unless code
    libs = @libs.get()
    styles = @styles.get()
    t = TEMPLATE + ""
    for lib in libs when lib
      t += "<script src='#{lib}'></script>"
    for style in styles when style
      t += "<link rel='stylesheet' href='#{lib}'></link>"

    data = @data.get() or {}
    if data.type == "json"
      DATA = '<script charset="UTF-8">var data = ' + data.text + '</script>'
    else if data.type == "csv"
      DATA = '<script charset="UTF-8">var data = d3.csv.parse(' + JSON.stringify(data.text) + ');</script>'
    else
      DATA = ""


    CODE = "<script>var module = {}; function Component() {};\n" + code.js + "</script>"

    t += "<style>\n" + code.css + "\n</style>" +
      TEMPLATEBODY + 
      code.html +
      ENDCUSTOM + 
      DATA + 
      CODE + 
      ENDTEMPLATE 

    #remove the last instance
    window.URL.revokeObjectURL(@blobUrl.get())
    blob = new Blob([t], {type: "text/html"})
    blob_url = URL.createObjectURL(blob)
    #console.log("url", blob_url)
    #var blob_iframe = document.querySelector('#blob-src-test');
    #console.log(self.inner);
    @inner.src = blob_url
    @blobUrl.set blob_url
