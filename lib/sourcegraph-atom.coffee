{CompositeDisposable} = require 'atom'
fs = require 'fs'

util = require './util'
IdentifierHighlighter = require './identifier-highlighter'
SrclibStatusView = require './srclib-status-view'
SearchView = require './sourcegraph-search-view'
ExamplesView = require './sourcegraph-examples-view'
CommandQueue = require './command-queue'

module.exports =
  config:
    goPath:
      type: 'string'
      default: ''
      description: '
        Path to your $GOPATH.
        Uses $GOPATH from env if not specified.
      '
    goRoot:
      type: 'string'
      default: ''
      description: '
        Path to your $GOROOT.
        Uses $GOROOT from env if not specified.
        Most people won\'t need to set this, even if their $GOROOT is unset.
        See http://dave.cheney.net/2013/06/14/you-dont-need-to-set-goroot-really
      '
    path:
      type: 'string'
      default: ''
      description: 'Add items to your PATH, separated by \':\''
    srcExecutablePath:
      type: 'string'
      default: ''
      description: '
        Path to src executable. By default, this assumes
        it is already in the path.
      '
    srcTimeout:
      type: 'number'
      default: 30000
      description: '
        Timeout for src command in miliseconds.
        After timeout expires `src` command will be terminated.
      '
    highlightReferencesInFile:
      type: 'boolean'
      default: true
    openMessagePanelOnError:
      type: 'boolean'
      default: true
    logStatusToConsole:
      type: 'boolean'
      default: false

  activate: (state) ->
    # Ensure that Atom's path has common src locations
    if '/usr/local/bin' not in process.env.PATH.split(':')
      process.env.PATH += ':/usr/local/bin'

    @statusView = new SrclibStatusView()
    @searchView = new SearchView(state.viewState)
    @commandQueue = new CommandQueue()
    @subscriptions = new CompositeDisposable

    # Defaults.
    state.enabled = true if not state.enabled?

    @highlighters = []
    atom.packages.onDidActivateInitialPackages =>
      atom.workspace.observeTextEditors (editor) =>
        hl = new IdentifierHighlighter(editor, @statusView, state.enabled,
          @commandQueue)
        @highlighters.push hl
        # When editor is destroyed remove highlighter.
        @subscriptions.add editor.onDidDestroy(=>
          @highlighters.splice(@highlighters.indexOf(hl), 1)
        )

    # Restore enabled state.
    # After toggle the state will be correct.
    @enabled = not state.enabled
    @toggle()

    # Add commands.
    @subscriptions.add atom.commands.add 'atom-workspace',
      'sourcegraph-atom:jump-to-definition': => @jumpToDefinition()
      'sourcegraph-atom:show-documentation-and-examples': => @docsExamples()
      'sourcegraph-atom:search-on-sourcegraph': => @searchOnSourcegraph()
      'sourcegraph-atom:toggle': => @toggle()

    @subscriptions.add @statusView.onToggle => @toggle()

    atom.workspace.addOpener (uri) ->
      console.log(uri)
      if uri is 'sourcegraph-atom://docs-examples'
        return new ExamplesView()
      else
        return null

  # Toggle state.
  toggle: ->
    console.log('main toggle')
    if @enabled then @disable() else @enable()
    return @enabled

  # Disable processing.
  disable: ->
    console.log('sourcegraph-atom: toggle disable')
    @statusView.disable()
    hl.disable() for hl in @highlighters
    @enabled = false

  # Enable processing.
  enable: ->
    console.log('sourcegraph-atom: toggle enable')
    @statusView.enable()
    hl.enable() for hl in @highlighters
    @enabled = true

  consumeStatusBar: (statusBar) ->
    # Attach status view
    @statusBarTile = statusBar.addLeftTile(item: @statusView, priority: 100)

  deactivate: ->
    @subscriptions?.dispose()
    @statusBarTile?.destroy()
    @statusBarTile = null

  jumpToDefinition: ->
    return if not @enabled

    editor = atom.workspace.getActiveTextEditor()
    filePath = editor.getPath()
    # Figure out project directory for editors file.
    [projectPath, relPath] = atom.project.relativizePath(filePath)

    offset = util.positionToByte(editor, editor.getCursorBufferPosition())
    command = "#{util.getSrcBin()} api describe
                --file=\"#{filePath}\"
                --start-byte=#{offset}
                --no-examples"

    @commandQueue.enqueue(command, projectPath,
      before: =>  @statusView.inprogress("Jump to Definition: #{command}")
      execCallback: (error, stdout, stderr) =>
        if error
          if error.killed
            @statusView.error("Command timed out.
              Try increasing `src timeout` in sourcegraph-atom settings.
              <br\>Command was: #{command}")
          else @statusView.error("#{command}: #{stderr}")
        else
          result = JSON.parse(stdout)

          def = result.Def
          if not def
            @statusView.warn('No reference found under cursor.')
          else
            if not def.Repo
              @statusView.success('Successfully resolved to local definition.')
              #FIXME: Only works when atom project path matches
              atom.workspace.open( def.File ).then( (editor) ->
                offset = util.byteToPosition(editor, def.DefStart)

                editor.setCursorBufferPosition(offset)
                editor.scrollToCursorPosition()
              )
            else
              @statusView.success('Successfully resolved to remote definition.')
              if fs.existsSync(def.File)
                atom.workspace
                  .open(def.File)
                  .then (editor) ->
                    pos = util.byteToPosition(editor, def.DefStart)
                    editor.setCursorScreenPosition(pos)
              else
                util.openBrowser(
                  "http://www.sourcegraph.com/#{def.Repo}/\
                  .#{def.UnitType}/#{def.Unit}/.def/#{def.Path}"
                )
    )

  docsExamples: ->
    return if not @enabled
    editor = atom.workspace.getActiveTextEditor()
    filePath = editor.getPath()
    offset = util.positionToByte(editor, editor.getCursorBufferPosition())
    command = "#{util.getSrcBin()} api describe
                --file=\"#{filePath}\"
                --start-byte=#{offset}"

    # Figure out project directory for editors file.
    [projectPath, relPath] = atom.project.relativizePath(filePath)

    @commandQueue.enqueue(command, projectPath,
      before: =>
        @statusView.inprogress("Documentation and Examples: #{command}")
      execCallback: (error, stdout, stderr) =>
        if error
          if error.killed
            @statusView.error("Command timed out.
              Try increasing `src timeout` in sourcegraph-atom settings.
              <br\>Command was: #{command}")
          else @statusView.error("#{command}: #{stderr}")
        else
          result = JSON.parse(stdout)
          if not result.Def
            @statusView.warn('No reference found under cursor.')
          else
            previousActivePane = atom.workspace.getActivePane()
            atom.workspace
              .open('sourcegraph-atom://docs-examples',
                split: 'right',
                searchAllPanes: true
              )
              .done (examplesView) =>
                examplesView.display(result)
                previousActivePane.activate()
                @statusView.success('Opened docs panel')
    )

  searchOnSourcegraph: ->
    return if not @enabled
    @searchView.toggle()

  # Serialize state so we can restore it after next load.
  serialize: ->
    enabled: @enabled
