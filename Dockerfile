FROM ruby:latest
ADD ./Gemfile ./Gemfile
RUN bundle install
ADD . /app
WORKDIR /app
