#!/bin/bash -e
if [ $RACK_ENV = "development" ]
then
  bundle install
  bundle exec rake db:migrate
fi

service nginx restart
bundle exec rackup -p ${1:-5000}
