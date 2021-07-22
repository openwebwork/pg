# Docker Instructions

These are instructions to get the docker image running for pg-unit tests

1. `cd $PG_ROOT`
2. `docker build -t pg-unit-test -f docker/pg-text-docker docker`, note: you may need sudo privileges.  The first time, this may take a couple of minutes.
3. `docker run -it --rm --name pg-unit-test -v "$PWD":/opt/webwork/pg pg-unit-test`

At this point you should get a prompt that you are in a shell in the docker container.

1. `cd /opt/webwork/pg`
2. `prove -r .`  This will run all of the tests.