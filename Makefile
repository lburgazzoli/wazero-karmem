MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
PROJECT_PATH := $(patsubst %/,%,$(dir $(MKFILE_PATH)))
LOCAL_BIN_PATH := ${PROJECT_PATH}/bin

# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

# Setting SHELL to bash allows bash commands to be executed by recipes.
# Options are set to exit when a recipe line exits non-zero or a piped command fails.
SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

.PHONY: all
all: build

##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

.PHONY: help
help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Development

.PHONY: fmt
fmt: goimport
	$(LOCALBIN)/goimports -l -w .
	go fmt ./...

.PHONY: test
test:
	go test ./pkg/...

.PHONY: deps
deps:
	go mod tidy

.PHONY: run
run:
	go run main.go

##@ Build

.PHONY: build
build: fmt
	CGO_ENABLED=0 go build -o $(LOCAL_BIN_PATH)/wk $(BUILD_TAGS) main.go

.PHONY: build/wasm
build/wasm:
	@docker run \
		--rm \
		-ti \
		-v $(PROJECT_PATH):/src:Z \
		-w /src \
		tinygo/tinygo:0.27.0 \
		tinygo build \
			-target=wasi \
			-scheduler=none \
			-gc=leaking \
			-o etc/fn/process.wasm  \
			etc/fn/process.go

.PHONY: generate
generate:
	go run karmem.org/cmd/karmem build --golang -o "pkg/interop" etc/message.km


##@ Build Dependencies

## Location to install dependencies to
LOCALBIN ?= $(shell pwd)/bin
$(LOCALBIN):
	@mkdir -p $(LOCALBIN)

## Tool Binaries
GOIMPORT ?= $(LOCALBIN)/goimports
KO ?= $(LOCALBIN)/ko

.PHONY: goimport
goimport: $(GOIMPORT)
$(GOIMPORT): $(LOCALBIN)
	@test -s $(LOCALBIN)/goimport || \
	GOBIN=$(LOCALBIN) go install golang.org/x/tools/cmd/goimports@latest

