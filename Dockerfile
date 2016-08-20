FROM convox/rails
RUN apt-get update
RUN apt-get install docker.io -y
ADD ./Gemfile ./Gemfile
ADD ./Gemfile.lock ./Gemfile.lock
RUN echo "54.186.104.15 rubygems.org" >> /etc/hosts
RUN bundle install
ADD . /app
WORKDIR /app
