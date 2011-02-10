express = require 'express'
#assetManager = require 'connect-assetmanager'
#assetHandler = require 'connect-assetmanager-handlers'

root = __dirname + '/public'

#assetManagerGroups =
  #'js':
    #'route': '/client\\.js/'
    #'path': './public/'
    #'dataType': 'javascript'
    #'files': ['negyeshatos.js']
    #'postManipulate':
      #'^': [assetHandler.yuiJsOptimize]


app = express.createServer(
  #express.logger(),
  express.compiler({src: root, enable: ['sass', 'coffeescript']}),
  express.staticProvider(root)
  express.cacheManifest(root)
  express.cache()
  express.gzip()
  #assetManager(assetManagerGroups)
)

app.listen 3000
