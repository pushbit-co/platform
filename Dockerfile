FROM convox/rails
RUN apt-get update
RUN apt-get install docker.io -y
ADD ./Gemfile ./Gemfile
ADD ./Gemfile.lock ./Gemfile.lock
RUN bundle install
ADD . /app
WORKDIR /app
