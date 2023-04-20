# Docker Instructions

These are instructions to build and use a docker image for running the unit tests in `/t`.

Note: You may need sudo privileges in order to run the `docker` commands.

## Building the Docker Image

Execute the following command from the directory containing your `pg` clone from GitHub.

```bash
docker build -t pg -f docker/pg.Dockerfile .
```

### Running the Test Suite

To run the tests execute the following command.

```bash
docker run -it --rm -v `pwd`:/opt/webwork/pg pg prove -r t
```

### Using the Shell

You can also open a `bash` shell in the Docker container via

```bash
docker run -it --rm -v `pwd`:/opt/webwork/pg pg
```

At the prompt, just run the commands `prove -r t` as above.
