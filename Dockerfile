FROM convox/rails
RUN apt-get update
RUN apt-get install curl -y
RUN curl -sSL https://get.docker.com/ | sh
RUN apt-get install docker-engine -y
ADD ./Gemfile ./Gemfile
ADD ./Gemfile.lock ./Gemfile.lock
RUN bundle install
ADD . /app
WORKDIR /app
