package tool

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
)

#ViteBuild: {
	source:     dagger.#FS
	configFile: string | *"vite.config.ts"
	env: [Key=string]:     string | dagger.#Secret
	mounts: [Name=string]: core.#Mount

	image: #NodeImage & {}

	workdir: "/app"

	_build: docker.#Run & {
		input:     image.output
		"workdir": workdir
		"env":     env
		"mounts": {
			mounts

			#BuildCacheMounts & {
				#caches: {
					// https://github.com/pnpm/pnpm/releases/tag/v7.0.0
					pnpm_store: "/root/.local/share/pnpm/store"
				}
			}

			codesource: core.#Mount & {
				dest:     workdir
				contents: source
			}
		}
		command: {
			name: "sh"
			flags: "-c": """
				echo "//npm.pkg.github.com/:_authToken=${GH_PASSWORD}" >> ~/.npmrc
				echo "@innoai-tech:registry=https://npm.pkg.github.com/" >> ~/.npmrc
				npm install -g pnpm
				pnpm --version
				pnpm config list
				pnpm install
				./node_modules/.bin/vite build --mode=production --config=\(configFile) --outDir=/output
				"""
		}
		export: directories: "/output": _
	}

	output: _build.export.directories."/output"
}

#NodeImage: {
	nodeVersion: string | *"18"

	packages: {
		"build-dep": _
	}

	#DebianBuild & {
		source: "node:\(nodeVersion)-\(#DebianVersion)"
	}
}