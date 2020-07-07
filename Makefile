SHELL=/bin/bash
BINARY=bin/http-gate

.SHELLFLAGS = -o pipefail -c

COMPILE_FLAGS=-Dstatic
BUILD_TARGET=

DOCKER=docker run -t -u `id -u`:`id -g` -v $(PWD):/v -w /v --rm crystallang/crystal:0.33.0

all: build

.PHONY: build
build:
	$(DOCKER) shards build $(COMPILE_FLAGS) --link-flags "-static" $(BUILD_TARGET) $(O)

.PHONY: http-gate-dev
http-gate-dev: BUILD_TARGET=http-gate-dev
http-gate-dev: build

.PHONY: http-gate
http-gate: BUILD_TARGET=--release http-gate
http-gate: build

.PHONY : github_release
github_release: bin/http-gate
	@if LC_ALL=C file "${BINARY}" | grep statically > /dev/null; then \
	  echo -e "static binary: ${BINARY} [\033[1;32mOK\033[0m]\n"; \
	else \
	  echo "not static binary: ${BINARY}" >&2; \
	fi
	./github_release

.PHONY: ci
ci: http-gate-dev spec

.PHONY : spec
spec:
	@$(DOCKER) crystal spec -v --fail-fast

VERSION=
CURRENT_VERSION=$(shell git tag -l | sort -V | tail -1 | sed -e 's/^v//')
GUESSED_VERSION=$(shell git tag -l | sort -V | tail -1 | awk 'BEGIN { FS="." } { $$3++; } { printf "%d.%d.%d", $$1, $$2, $$3 }')

.PHONY : version
version:
	@if [ "$(VERSION)" = "" ]; then \
	  echo "ERROR: specify VERSION as bellow. (current: $(CURRENT_VERSION))";\
	  echo "  make version VERSION=$(GUESSED_VERSION)";\
	else \
	  sed -i -e 's/^version: .*/version: $(VERSION)/' shard.yml ;\
	  sed -i -e 's/^    version: [0-9]\+\.[0-9]\+\.[0-9]\+/    version: $(VERSION)/' README.md ;\
	  echo git commit -a -m "'$(COMMIT_MESSAGE)'" ;\
	  git commit -a -m 'version: $(VERSION)' ;\
	  git tag "v$(VERSION)" ;\
	fi

.PHONY : bump
bump:
	make version VERSION=$(GUESSED_VERSION) -s
