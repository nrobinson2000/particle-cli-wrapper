package main

import (
	"flag"
	"github.com/particle-iot/particle-cli-wrapper/Godeps/_workspace/src/github.com/lunixbochs/vtclean"
	"io"
	"os"
)

func main() {
	color := flag.Bool("color", false, "enable color")
	flag.Parse()

	stdin := vtclean.NewReader(os.Stdin, *color)
	io.Copy(os.Stdout, stdin)
}
