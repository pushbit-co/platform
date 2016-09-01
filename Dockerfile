FROM convox/rails
RUN apt-get update
RUN apt-get install docker.io -y
RUN apt-get install npm -y
RUN ln -s /usr/bin/nodejs /usr/bin/node

WORKDIR /app
ADD . /app

ADD ./package.json ./package.json
RUN npm config set registry http://registry.npmjs.org/
RUN npm install
RUN npm run build

ADD ./Gemfile ./Gemfile
ADD ./Gemfile.lock ./Gemfile.lock
RUN bundle install
