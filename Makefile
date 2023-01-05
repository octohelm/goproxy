WAGON = wagon -p ./wagon.cue

build:
	$(WAGON) do go build
.PHONY: build

ship:
	$(WAGON) do go ship pushx
.PHONY: push
