FROM ruby:latest
ADD ./Gemfile ./Gemfile
ADD ./Gemfile.lock ./Gemfile.lock
RUN bundle install
ADD . /app
WORKDIR /app
