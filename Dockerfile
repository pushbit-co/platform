FROM convox/rails
RUN apt-get update
RUN apt-get install curl -y
RUN curl -sSL https://get.docker.com/ | sh
RUN apt-get install docker-engine -y

RUN apt-get install npm -y
RUN ln -s /usr/bin/nodejs /usr/bin/node
RUN npm config set registry http://registry.npmjs.org/

ADD ./Gemfile ./Gemfile
ADD ./Gemfile.lock ./Gemfile.lock
WORKDIR /app
ADD . /app

RUN bundle install --jobs 20 --retry 5

ADD ./package.json ./package.json
RUN npm i && npm i -g webpack
RUN npm run build

RUN RACK_ENV=production PRECOMPILE=true bundle exec rake assets:precompile --trace
