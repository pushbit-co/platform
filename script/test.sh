docker build -f ./Dockerfile -t platform/platform .
docker run --rm -t --env-file=.env platform/platform bundle exec rspec
