package main

import (
	"strings"
	"wagon.octohelm.tech/core"

	"github.com/innoai-tech/runtime/cuepkg/debian"
	"github.com/innoai-tech/runtime/cuepkg/golang"
)

pkg: {
	version: core.#Version & {
	}
}

actions: go: golang.#Project & {
	source: {
		path: "."
		include: [
			"cmd/",
			"pkg/",
			"go.mod",
			"go.sum",
		]
	}

	tag: pkg.version.output

	goos: ["linux"]
	goarch: ["amd64", "arm64"]
	main: "./cmd/goproxy"
	ldflags: [
		"-s -w",
		"-X \(go.module)/pkg/version.Version=\(go.version)",
	]

	ship: {
		name: "\(strings.Replace(actions.go.module, "github.com/", "ghcr.io/", -1))"
		tag:  pkg.version.output

		from: "golang:1.20-bullseye"
		steps: [
			debian.#InstallPackage & {
				packages: {
					"ca-certificates": _
				}
			},
		]
		config: {
			env: {
				PORT: "80"
			}
		}
	}
}

setting: {
	_env: core.#ClientEnv & {
		GH_USERNAME: string | *""
		GH_PASSWORD: core.#Secret
	}

	setup: core.#Setting & {
		registry: "ghcr.io": auth: {
			username: _env.GH_USERNAME
			secret:   _env.GH_PASSWORD
		}
	}
}
