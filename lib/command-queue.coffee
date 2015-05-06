{getEnv} = require './util'
{exec} = require 'child_process'

module.exports =
# CommandQueue runs commands in sequence.
class CommandQueue
  # Initialize CommandQueue.
  constructor: -> @queue = []

  # Add new command to queue.
  # If queue is empty the command will be exectued immediately.
  # cbs is object with 2 optional properties:
  #  - before: function() - called before exec
  #  - execCallback: function(error, stdout, stderr) - passed as exec callback
  enqueue: (command, cwd, cbs) ->
    @queue.push([command, cwd, cbs])
    if @queue.length is 1 then @execute()

  # Execute given command.
  execute: ->
    if @queue.length is 0 then return

    [command, cwd, cbs] = @queue[0]

    wrappedCB = =>
      cbs?.execCallback?(arguments...)
      # Remove processed command.
      @queue.shift()
      # Execute next command.
      if @queue.length > 0 then @execute()

    cbs?.before?()
    exec(command,
      maxBuffer: 200 * 1024 * 100,
      env: getEnv(),
      cwd: cwd,
      timeout: atom.config.get('sourcegraph-atom.srcTimeout'),
      wrappedCB)
