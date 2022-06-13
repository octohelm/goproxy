export GIT_SHA ?= $(shell git rev-parse HEAD)
export GIT_REF ?= HEAD

DAGGER = dagger --log-format=plain -p ./

build:
	$(DAGGER) do build
.PHONY: build

ship:
	$(DAGGER) do ship
.PHONY: push
