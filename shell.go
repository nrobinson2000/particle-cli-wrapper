package main

import (
	"os"
	"strings"
)

// Run parses command line arguments and runs the associated command or help.
// The shell handles updating itself and forwards all other commands to the core
func runCommand(args []string) error {
	// update is a special command that runs in the Go shell
	if len(args) > 1 && args[1] == "update-cli" {
		return runUpdateCommand(args)
	} else {
		return runCoreCommand(args)
	}
}

func processTitle() string {
	return "particle " + strings.Join(os.Args[1:], " ")
}
