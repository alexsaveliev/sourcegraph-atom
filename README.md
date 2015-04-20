# Sourcegraph-Atom

A plugin for Github's Atom editor that integrates with srclib and the
Sourcegraph API.

![Screenshot][screenshot]

[screenshot]: http://goo.gl/fynEVr

## Known issues

This is still work in progress.

 - Go is the most stable toolchain (language support). Other languages
   are not as well supported as Go.
 - Race condition in `src`. Sometimes when running multiple `src`
   commands at the same time they will fail. This is going to be fixed
   upstream (in the `src` tool) soon.

## Current features:

 - Jump To Definition
 - See Documentation
 - Find Usage Examples on Sourcegraph

## Installation

### Requirements

This plugin requires that the srclib tool is installed, as well as the
language toolchains for the individual languages that you wish to use.

Follow the [srclib installation instructions here][src-install].

[src-install]: http://srclib.org/gettingstarted/#install-srclib

### Installing from APM

To install from APM you can either install from command line:

```bash
apm install sourcegraph-atom
```

or open Atom and go to `Preferences > Packages`, search for
`sourcegraph-atom`, and install it.

> This plugin queries Sourcegraph. Your private code is never
> uploaded, but information about the identifier under the cursor is
> used to construct the query. This includes information such as the
> clone URL of the repository you're currently in, the filename and
> character position, and the name of the current identifier
> definition.
