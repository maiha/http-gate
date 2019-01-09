SHELL=/bin/bash
BINARY=bin/http-gate

VERSION=
CURRENT_VERSION=$(shell git tag -l | sort -V | tail -1)
GUESSED_VERSION=$(shell git tag -l | sort -V | tail -1 | awk 'BEGIN { FS="." } { $$3++; } { printf "%d.%d.%d", $$1, $$2, $$3 }')

.SHELLFLAGS = -o pipefail -c

.PHONY : all
all:
	shards build

.PHONY : release
release: static
	./github_release

.PHONY : static
static:
	rm -f ${BINARY}
	crystal build ${BUILD_FLAGS} src/bin/http-gate.cr -o ${BINARY} --release --link-flags "-static" 
	@if LC_ALL=C file "${BINARY}" | grep statically > /dev/null; then \
	  echo -e "static binary: ${BINARY} [\033[1;32mOK\033[0m]\n"; \
	else \
	  echo "not static binary: ${BINARY}" >&2; \
	fi

.PHONY : test
test: spec

.PHONY : spec
spec:
	crystal spec -v --fail-fast

.PHONY : check_version_mismatch
check_version_mismatch: shard.yml README.md
	diff -w -c <(grep version: README.md) <(grep ^version: shard.yml)

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
