.PHONY: all templates test test-deps vendor

all: start

start:
	docker-compose up

test:
	docker-compose run platform bundle exec rspec
