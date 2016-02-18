{exec} = require('child_process')
pathpkg = require 'path'

module.exports =
  # Get `srclib` binary location.
  getSrcBin: ->
    location = atom.config.get('sourcegraph-atom.srcExecutablePath').trim()
    return if location.length then location else 'srclib'

  # Get process ENV. Also sets GOPATH and GOROOT and adjusts GOPATH.
  getEnv: ->
    goPath = atom.config.get('sourcegraph-atom.goPath').trim()
    if goPath.length
      process.env.GOPATH = goPath
    goRoot = atom.config.get('sourcegraph-atom.goRoot').trim()
    if goRoot.length
      process.env.GOROOT = goRoot
    path = atom.config.get('sourcegraph-atom.path').trim()
    for p in path.split(pathpkg.delimiter)
      if p not in process.env.PATH.split(pathpkg.delimiter)
        process.env.PATH += pathpkg.delimiter + p
    return process.env

  # Open browser.
  openBrowser: (url) ->
    console.log("Opening #{url} ...")
    switch process.platform
      when 'linux'
        exec("xdg-open \"#{url}\"")
      when 'darwin'
        exec("open \"#{url}\"")
      when 'win32'
        # TODO: Confirm that this works on Windows
        exec("start \"#{url}\"")
      else
        console.log('Unable to open web browser - unkown platform.')

  # Convert byte position to editor position.
  byteToPosition: (editor, byte) ->
    # FIXME: Only works for ASCII
    editor.getBuffer().positionForCharacterIndex(byte)

  # Convert editor position to byte position.
  positionToByte: (editor, point) ->
    # FIXME: Only works for ASCII
    editor.getBuffer().characterIndexForPosition(point)
