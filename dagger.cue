package main

import (
	"strings"

	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"

	"github.com/octohelm/goproxy/cuepkg/tool"
)

dagger.#Plan & {
	client: {
		env: {
			VERSION: string | *"dev"

			GIT_SHA: string | *""
			GIT_REF: string | *""

			GOPROXY:   string | *""
			GOPRIVATE: string | *""
			GOSUMDB:   string | *""

			GH_USERNAME: string | *""
			GH_PASSWORD: dagger.#Secret
		}
	}

	actions: {
		_source: core.#Source & {
			path: "."
			include: [
				"cmd/",
				"pkg/",
				"go.mod",
				"go.sum",
			]
		}

		_env: {
			for k, v in client.env if k != "$dagger" {
				"\(k)": v
			}
		}

		_imageName: "ghcr.io/octohelm/goproxy"

		_version: [
				if strings.HasPrefix(_env.GIT_REF, "refs/tags/v") {
				strings.TrimPrefix(_env.GIT_REF, "refs/tags/v")
			},
			if strings.HasPrefix(_env.GIT_REF, "refs/heads/") {
				strings.TrimPrefix(_env.GIT_REF, "refs/heads/")
			},
			_env.VERSION,
		][0]

		_tag: _version

		info: tool.#GoModInfo & {
			source: _source.output
		}

		_archs: ["amd64", "arm64"]

		build: tool.#GoBuild & {
			source: _source.output
			targetPlatform: {
				arch: _archs
				os: ["linux", "darwin"]
			}
			run: {
				env: _env
			}
			ldflags: [
				"-s -w",
				"-X \(info.module)/pkg/version.Version=\(_version)",
				"-X \(info.module)/pkg/version.Revision=\(_env.GIT_SHA)",
			]
			package: "./cmd/goproxy"
		}

		image: {
			for _arch in _archs {
				"linux/\(_arch)": docker.#Build & {
					steps: [
						tool.#DebianBuild & {
							packages: {
								"ca-certificates": _
							}
						},
						docker.#Copy & {
							contents: build["linux/\(_arch)"].output
							source:   "./goproxy"
							dest:     "/goproxy"
						},
						docker.#Set & {
							config: {
								label: {
									"org.opencontainers.image.source":   "https://\(info.module)"
									"org.opencontainers.image.revision": "\(_env.GIT_SHA)"
								}
								workdir: "/"
								entrypoint: ["/goproxy"]
							}
						},
					]
				}
			}
		}

		push: docker.#Push & {
			dest: "\(_imageName):\(_tag)"
			images: {
				for _arch in _archs {
					"linux/\(_arch)": image["linux/\(_arch)"].output
				}
			}
			auth: {
				username: _env.GH_USERNAME
				secret:   _env.GH_PASSWORD
			}
		}
	}
}
