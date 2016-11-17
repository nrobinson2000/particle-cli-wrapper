package main

import (
	"os"
	"strings"
)

// Run parses command line arguments and runs the associated command or help.
// The shell handles updating itself and forwards all other commands to the core
func runCommand(args []string) {
	// update is a special command that runs in the Go shell
	if len(args) > 1 && args[1] == "update-cli" {
		runUpdateCommand(args)
	} else {
		runCoreCommand(args)
	}
}

func processTitle() string {
	return "particle " + strings.Join(os.Args[1:], " ")
}
