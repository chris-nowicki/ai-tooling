.PHONY: sync check dry-run setup update-vendored

sync:
	rulesync generate -g

check:
	rulesync generate -g --check

dry-run:
	rulesync generate -g --dry-run

setup:
	chmod +x setup.sh && ./setup.sh

update-vendored:
	chmod +x scripts/update-vendored.sh && ./scripts/update-vendored.sh
