#!/bin/bash -e

if [ $RACK_ENV = "development" ]
then
  bundle check || bundle install
fi

bundle exec sidekiq -r ./workers.rb
