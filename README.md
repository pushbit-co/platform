# Pushbit Platform

Pushbit is a platform for automated workflows built ontop of GitHub. Pushbit takes care of hundreds of tedious tasks through pre built behaviors so your team can spend their time writing great software. Check out more about Pushbit on our [homepage](https://www.pushbit.co).

## Environment

We recommend using Docker, Machine and Compose for development.
First, create a VM using [docker machine and the virtual box driver](https://docs.docker.com/machine/get-started/).

## Development

There are two main prerequisites to getting a development environment up and running.
You need to copy your docker TLS certificates from their install location into ./docker_cert_path in the project root (this allows Pushbit to automatically spin up containers to run behaviors).

You can find their location by running the following command. (Swap `default` with your chosen name if you specified one during the creation of your machine)

```
docker-machine env default
```

Secondly you will need to copy .env.example to a file called .env in the project root and replace with your own development keys. Once this is done you should be able to run a local version of Pushbit with the following:

```
docker-compose up
```


## Tests

Tests also run inside the development docker container, use the following command:

```
./script/test.sh
```

If you get gem errors you'll need to make sure they are installed first, you can do this automatically by running the app first:

```
docker-compose up
```


## Contributing

* Open a [GitHub Issue](https://github.com/pushbit-co/platform/new) for bugs and feature requests
* Initiate a [GitHub Pull Request](https://help.github.com/articles/using-pull-requests/) for patches
* Don't be shocked if Pushbit comments on your PR 😉
