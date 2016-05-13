package main

import (
	"fmt"
	"runtime"
)

func version() string {
	return fmt.Sprintf("particle/%s (%s-%s) %s", Version, runtime.GOARCH, runtime.GOOS, runtime.Version())
}
