PKG = $(shell cat go.mod | grep "^module " | sed -e "s/module //g")
VERSION = $(shell cat internal/version/version)
COMMIT_SHA ?= $(shell git rev-parse --short HEAD)
TAG ?= dev

TARGET ?= goproxy
TARGET_PLATFORMS ?= $(GOOS)/amd64

GOOS ?= $(shell go env GOOS)
GOARCH ?= $(shell go env GOARCH)
GO_LDFLAGS = -trimpath -ldflags="-s -w -X github.com/go-courier/goproxy/pkg/version.Version=$(VERSION)+sha.$(COMMIT_SHA)"

up:
	go run ./cmd/$(TARGET)

fmt:
	goimports -l -w .

dep:
	go get -u -t ./...

tidy:
	go mod tidy

build: GOOS = linux
build: GOARCH = amd64 arm64
build: tidy
	@$(foreach os,$(GOOS), \
		$(foreach arch,$(GOARCH), \
			$(MAKE) build.bin GOOS=$(os) GOARCH=$(arch); \
		)\
	)

build.bin:
	CGO_ENABLED=0 go build $(GO_LDFLAGS) \
		-o ./bin/$(TARGET)-$(GOOS)-$(GOARCH) ./cmd/$(TARGET)

DOCKER_NAMESPACES ?= ghcr.io/querycap
DOCKER_LABELS ?= org.opencontainers.image.source=https://$(PKG) org.opencontainers.image.revision=$(COMMIT_SHA)
DOCKER_FLAGS ?=

lastword-of = $(word $(words $1),$1)

docker.%: TARGET = $(call lastword-of,$(subst ., ,$*))
docker.%: build
	docker buildx build \
		$(DOCKER_FLAGS) \
		$(foreach label,$(DOCKER_LABELS),--label=$(label)) \
	  	$(foreach namespace,$(DOCKER_NAMESPACES),--tag=$(namespace)/$(TARGET):$(TAG)) \
		--file=cmd/$(TARGET)/Dockerfile .

docker.push.%: DOCKER_FLAGS = $(foreach arch,$(GOARCH),--platform=linux/$(arch)) --push
docker.push.%: docker.%