.PHONY: test check install

BATS ?= $(if $(wildcard .opencode/node_modules/.bin/bats),.opencode/node_modules/.bin/bats,bats)

test:
	bash tests/test.bash
	$(BATS) --formatter tap --jobs 1 tests/regressions.bats

check:
	@set -e; for file in install.sh init.bash bin/client components.d/*.bash tests/*.bash examples/*/*.bash examples/*/*.env; do bash -n "$$file"; done

install:
	bash install.sh
