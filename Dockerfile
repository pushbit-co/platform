FROM ruby:latest
ADD ./Gemfile ./Gemfile
ADD ./Gemfile.lock ./Gemfile.lock
RUN echo "54.186.104.15 rubygems.org" >> /etc/hosts
RUN bundle install
ADD . /app
WORKDIR /app
