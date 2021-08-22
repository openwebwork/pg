# Docker Instructions

These are instructions to get the docker image running for running the unit tests in `/t`. 

Note: You may need sudo privileges in order to run the commands starting with `docker ...`.

## Using the Image from Docker Hub

The following Docker command will execute the command `prove -r t` inside the Docker container from the image [`eltenedor/pg-no-ww:latest`](https://hub.docker.com/r/eltenedor/pg-no-ww).
Make sure to run the commands from your `pg` folder.
The first time, this may take a couple of minutes.

### Running the Test Suite

```bash
docker run -it --rm --name pg-unit-test -v `pwd`:/opt/webwork/pg -w /opt/webwork/pg eltenedor/pg-no-ww prove -r t
```

### Code Coverage

As above, run one of the following Docker commands from you `pg` folder.

#### HTML Output

This runs the command `cover -report html` in the Docker container.

```bash
docker run -it --rm --name pg-unit-test -v `pwd`:/opt/webwork/pg -w /opt/webwork/pg eltenedor/pg-no-ww cover -report html
```

Check the HTML output written to `./pg/cover_db/coverage.html`.

#### Publish Results to [`codecov.io`](https://about.codecov.io/)

```bash
docker run -it --rm --name pg-unit-test -v `pwd`:/opt/webwork/pg -w /opt/webwork/pg -e CODECOV_TOKEN=xxxx-xxxx-xxxx eltenedor/pg-no-ww cover -report codecov
```

Here, `CODECOV_TOKEN=xxxx-xxxx-xxxx` should be adapted to your actual [token](https://docs.codecov.com/docs/quick-start). It is passed to the docker container as argument to the `-e` option.

HTTP Code `200` means that the data was sent successfully to codecov and is availablle at https://app.codecov.io/gh/pstaabp/pg

### Using the Shell

You can also just open up the `bash` of the Docker container via
```bash
docker run -it --rm --name pg-unit-test -v `pwd`:/opt/webwork/pg -w /opt/webwork/pg eltenedor/pg-no-ww
```

At the prompt, just run the commands `prove -r t` and `cover -report html` as indicated above.

## Building the Docker Image Locally

Execute the following command from your `pg/docker` folder

```bash
docker build -t pg-no-ww -f pg-no-dww.Dockerfile
```

### Running the Test Suite

Same as above for the image from Docker Hub. Just replace the name `eltenedor/pg-no-ww` by `pg-no-ww`.

