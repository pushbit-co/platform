FROM convox/rails
RUN apt-get update
RUN apt-get install curl -y

RUN apt-get install npm -y
RUN ln -s /usr/bin/nodejs /usr/bin/node
RUN npm config set registry http://registry.npmjs.org/

ADD ./Gemfile ./Gemfile
ADD ./Gemfile.lock ./Gemfile.lock
RUN bundle install

WORKDIR /app
ADD . /app

ADD ./package.json ./package.json
RUN npm install -g webpack
RUN npm install
RUN npm run build
