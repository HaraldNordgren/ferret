.PHONY: build compile install test e2e doc fmt lint vet release

export GOPATH

VERSION ?= $(shell git describe --tags --always --dirty)
RELEASE_VERSION ?= $(version)
DIR_BIN = ./bin
DIR_PKG = ./pkg
DIR_CLI = ./cli
DIR_E2E = ./e2e

default: build

build: install vet generate test compile

compile:
	go build -v -o ${DIR_BIN}/ferret \
	-ldflags "-X main.version=${VERSION}" \
	./main.go

install:
	dep ensure

test:
	go test -race ${DIR_PKG}/...

cover:
	go test -race -coverprofile=coverage.txt -covermode=atomic ${DIR_PKG}/...
ifeq ($(TRAVIS_BRANCH)$(TRAVIS_PULL_REQUEST), masterfalse)
ifneq ($(CODECOV_TOKEN), )
	curl -s https://codecov.io/bash | bash
else
	$(error "CODECOV_TOKEN token is required")
endif
endif

e2e:
	go run ${DIR_E2E}/main.go --tests ${DIR_E2E}/tests --pages ${DIR_E2E}/pages

bench:
	go test -run=XXX -bench=. ${DIR_PKG}/...

generate:
	go generate ${DIR_PKG}/...

doc:
	godoc -http=:6060 -index

# http://golang.org/cmd/go/#hdr-Run_gofmt_on_package_sources
fmt:
	go fmt ${DIR_CLI}/... ${DIR_PKG}/...

# https://github.com/mgechev/revive
# go get github.com/mgechev/revive
lint:
	revive -config revive.toml -formatter friendly -exclude ./pkg/parser/fql/... -exclude ./vendor/... ./...

# http://godoc.org/code.google.com/p/go.tools/cmd/vet
# go get code.google.com/p/go.tools/cmd/vet
vet:
	go vet ${DIR_CLI}/... ${DIR_PKG}/...

release:
ifeq ($(RELEASE_VERSION), )
	$(error "Release version is required (version=x)")
else ifeq ($(GITHUB_TOKEN), )
	$(error "GitHub token is required (GITHUB_TOKEN)")
else
	rm -rf ./dist && \
	git tag -a v$(RELEASE_VERSION) -m "New $(RELEASE_VERSION) version" && \
	git push origin v$(RELEASE_VERSION) && \
	goreleaser
endif