# Docker Instructions

These are instructions to get the docker image running for pg-unit tests. 
The environment variable `${PG_ROOT}` may not be set in your system or differ from the instance of `pg` that you are using.
In this case, replate all occurences of `${PG_ROOT}` by your working copy of `pg`.

1. `cd ${PG_ROOT}/docker` 
2. `docker build -t pg-no-ww -f pg-no-dww.Dockerfile .` \
note: you may need sudo privileges.  The first time, this may take a couple of minutes.
3. `docker run -it --rm --name pg-unit-test -v ${PG_ROOT}:/opt/webwork/pg -w /opt/webwork/pg pg-no-ww prove -r t`

This will run all of the tests. In order to generate a code coverage report additionally run

4. `docker run -it --rm --name pg-unit-test -v ${PG_ROOT}:/opt/webwork/pg -w /opt/webwork/pg -e CODECOV_TOKEN=xxxx-xxxx-xxxx pg-no-ww cover -report codecov`

where `CODECOV_TOKEN=xxxx-xxxx-xxxx` should be adapted to your actual token.

## Using the Image from Docker Hub

You can also pull and run a suitable image from hub.docker.com. To this end, skip steps 1 and 2 and, in replace all occurrences of `pg-no-ww` by `eltenedor/pg-no-ww`
