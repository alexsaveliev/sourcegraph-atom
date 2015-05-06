## 0.2.2 Command Queue

 * Add timeout to src calls to make sure that there are no zombie
   processes.
 * Execute commands sequentially. This should work around some issues
   `src` currently has while better fix is implemented upstream. This
   can result in some commands becoming out of sync with current file
   state. This is only temporary until there is a better fix.

## 0.2.1 Bugfix release

 * Set current working dir for all invocations of `src` tool.

## 0.2 Jump-to-awesome

 * On fresh install have the plugin in enabled state. Issue #18.
 * Fix deprecation warnings.
 * `jump-to-definition` now tries to open local file first before
   falling back to opening `sourcegraph.com`.
 * Fix `This TextEditor has been destroyed` error. Issue #17.
 * Fix plugin failing when more than one Atom window is open. Issue
   #20.
 * Highlight references when Atom is started and has buffers
   open. Issue #21.

## 0.1.1 - First APM Release

 * Released to APM.

## 0.1.0 - First Release

 * Fix Atom deprecation warnings
 * Update for Atom `1.0` API.

## 0.0.1 - First Release

 * Every feature added
 * Every bug fixed
