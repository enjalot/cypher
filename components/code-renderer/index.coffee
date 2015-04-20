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
    Usually this is a dangerous combination, and you shouldn't use it in
    untrusted environments. It would be safer if we could take off allow-same-origin
    but it's useful for 2 reasons. #1 derby-standalone doesn't work in a sandboxed iframe
    because it tries to take over the window.history and the browser complains. I'm pretty sure
    that could be made optional.
    2nd reason is that we can reach up and pull data right out of the main admin2 context. I'm passing in
    some data/code by creating a big string, which gets expensive if you make the string bigger.
    Directly referencing the data is nice and fast, the proper way would be postMessage but again, since
    this is a trusted environment we should take advantage of it
    ###
    @inner.sandbox = "allow-scripts"

    @runCode()
    # when the code changes lets rebuild the iframe
    @code.on("change", "**", @runCode.bind(@))
    @data.on("all", "**", @runCode.bind(@))
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

    t += "<style>\n" + code.css + "\n</style>" +
      TEMPLATEBODY + 
      code.html +
      ENDCUSTOM + 
      '<script charset="UTF-8">var data = ' +
      JSON.stringify(@data.get()).replace(/\u2028/g, '') +

      "</script>" +
      "<script>var module = {}; function Component() {};\n" + 
      code.js + 
      "</script>" +
      ENDTEMPLATE 

    #console.log("template", t);

    #remove the last instance
    window.URL.revokeObjectURL(@blobUrl.get())
    blob = new Blob([t], {type: "text/html"})
    blob_url = URL.createObjectURL(blob)
    #console.log("url", blob_url)
    #var blob_iframe = document.querySelector('#blob-src-test');
    #console.log(self.inner);
    @inner.src = blob_url
    @blobUrl.set blob_url
