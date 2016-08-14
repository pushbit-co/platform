#!/bin/bash -e

if [ $RACK_ENV = "development" ]
then
  sleep 6
  bundle check || bundle install
fi

bundle exec sidekiq -r ./workers.rb
