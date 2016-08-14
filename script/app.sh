#!/bin/bash -e
if [ $RACK_ENV = "development" ]
then
  bundle check || bundle install
  bundle exec rake db:migrate
fi

bundle exec rackup -p ${1:-8080}
