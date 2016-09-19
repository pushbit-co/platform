#!/bin/bash -e
# docker build -f ./Dockerfile -t platform/platform .
# id=`docker run -d  --name test_database -p 5432:5432 -e POSTGRES_DATABASE=test convox/postgres`
# docker run --rm -t --env-file=.env --link test_database:database platform/platform bundle exec rspec
# c=$?
# docker kill $id
# exit $c
docker-compose build platform
docker-compose run --rm platform bundle exec rspec

