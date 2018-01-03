package main

import "github.com/particle-iot/particle-cli-wrapper/Godeps/_workspace/src/github.com/toqueteos/webbrowser"

func main() {
	webbrowser.Open("http://golang.org")
	webbrowser.Open("http://reddit.com")
}
