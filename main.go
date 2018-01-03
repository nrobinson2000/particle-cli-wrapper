package main

import (
	"errors"
	"fmt"
	"os"
	"runtime"
	"runtime/debug"
	"strings"

	"github.com/particle-iot/particle-cli-wrapper/Godeps/_workspace/src/github.com/stvp/rollbar"
)

// Version is the version of the CLI.
// This is set by a build flag in the `Rakefile`.
var Version = "dev"

// Channel is the git branch the code was compiled on.
// This is set by a build flag in the `Rakefile` based on the git branch.
// If it is set to `?` it will not autoupdate.
var Channel = "?"

// BuiltinPlugins are the core plugins that will be autoinstalled
var BuiltinPlugins = []string{
	"particle-cli",
}

func init() {
	rollbar.Platform = "client"
	rollbar.Token = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
	rollbar.Environment = Channel
	rollbar.ErrorWriter = nil
}

func main() {
	defer handlePanic()
	runtime.GOMAXPROCS(1) // more procs causes runtime: failed to create new OS thread on Ubuntu
	ShowDebugInfo()
	Update(Channel, "block")
	SetupNode()
	SetupCore()
	err := runCommand(os.Args)
	TriggerBackgroundUpdate()
	if err != nil {
		os.Exit(getExitCode(err))
	}
}

func handlePanic() {
	if rec := recover(); rec != nil {
		err, ok := rec.(error)
		if !ok {
			err = errors.New(rec.(string))
		}
		Errln("ERROR:", err)
		if Channel == "?" {
			debug.PrintStack()
		} else {
			rollbar.Error(rollbar.ERR, err, rollbarFields()...)
			rollbar.Wait()
		}
		Exit(1)
	}
}

func rollbarFields() []*rollbar.Field {
	var cmd string
	if len(os.Args) > 1 {
		cmd = os.Args[1]
	}
	return []*rollbar.Field{
		{"Version", Version},
		{"GOOS", runtime.GOOS},
		{"GOARCH", runtime.GOARCH},
		{"command", cmd},
	}
}

// ShowDebugInfo prints debugging information if PARTICLE_DEBUG=1
func ShowDebugInfo() {
	if !isDebugging() {
		return
	}
	info := []string{version(), binPath}
	if len(os.Args) > 1 {
		info = append(info, fmt.Sprintf("cmd: %s", os.Args[1]))
	}
	Debugln(strings.Join(info, " "))
}
