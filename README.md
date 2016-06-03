# Particle CLI Wrapper

This tools is a wrapper around the [Particle CLI](https://github.com/spark/particle-cli) that manages the version of Node.js used and auto-updates the Javascript modules.

# [Install through the Particle website](https://www.particle.io/cli)

_If you already have the CLI installed, uninstall it with `npm uninstall -g particle-cli`_

## Overview

**The Particle CLI Wrapper is a delicacy consisting of a light Go shell filled with a sweet creamy Node.js core.**

The Go shell manages its own Node.js installation. It is able to update itself, Node and Node modules. It forwards commands to the main Node.js CLI module. Since it is compiled natively for each platform it is easy to install.

The Node.js core is today's production Particle CLI. It performs all interactions with the Particle cloud.

## Architecture

The version of Node.js to be installed to run the CLI is selected in [`set-node-version`](/set-node-version). When this script is run, the installation files for Node.js and npm for Mac OSX, Windows and Linux are downloaded from <nodejs.org> then uploaded to <binaries.particle.io>

The CLI wrapper is compiled for Mac OSX, Windows and Linux with `rake build` and uploaded to <binaries.particle.io> with `rake release`

A manifest file is also uploaded at <https://binaries.particle.io/cli/master/manifest.json> with the latest version of the CLI wrapper for each platform and the Node.js version that should be installed.

When the CLI wrapper is run, it will download the manifest file. It will check if there's a new version of itself and download it. If the managed version of Node.js is missing or there is a new one, it will download and install Node.js. If the main Node.js module `particle-cli` is missing or there's a new version on npm, it will download and install it.

The managed version of Node.js, the modules and the CLI wrapper executable are stored in `~/.particle` or `C:\Users\name\AppData\Local\particle`

## Installer

See the [installer directory](/installer) for the source code of the Mac OSX, Windows and Linux installers that downloads the latest CLI wrapper and runs it once to make Node.js install.

## Development

- Install godep `go get github.com/tools/godep`
- Clone repo into your Go workspace. For example, `~/go/src/github.com/particle/particle-cli-wrapper`
- cd to that folder
- Install dependencies `godep get`
- Build executable `go build`
- Run `./particle-cli-wrapper`

## License

Copyright 2016 © Particle Industries, Inc. Licensed under the Apache 2 license.

[Based on the Heroku CLI](https://github.com/heroku/heroku-cli)

