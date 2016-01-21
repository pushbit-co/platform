# Pushbit Platform

Pushbit is a platform for automated code changes and github bots

## Environment

We recommend using Docker, Machine and Compose for development.
Create a VM using [docker machine and the virtual box driver](https://docs.docker.com/machine/get-started/).

## Development

There are currently two main prerequisites to getting a development environment up and running.
You need to copy your docker TLS certificates from their install location into ./docker_cert_path in the project root.

You can find their location by running the following command. (Swap default with your chosen name if you specified one during the creation of your machine)

```
docker-machine env default
```

Secondly you will need to copy .env.example to a file called .env in the project root and replace with appropriate keys

## Test

```
docker-compose run --rm platform bundle exec rspec
```

## Contributing

* Open a [GitHub Issue](https://github.com/pushbit-co/platform/new) for bugs and feature requests
* Initiate a [GitHub Pull Request](https://help.github.com/articles/using-pull-requests/) for patches
