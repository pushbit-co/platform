FROM ruby:latest
RUN apt-get update && apt-get install -y --no-install-recommends \
  libpq-dev \
  libgmp-dev
RUN gem install bundler
ADD ./Gemfile ./Gemfile
RUN bundle install
ADD . /app
WORKDIR /app
