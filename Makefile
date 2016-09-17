.PHONY: all templates test test-deps vendor

all: start

start:
	convox start --no-sync

test:
	./script/test.sh
