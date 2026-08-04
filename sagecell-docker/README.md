# SageCell Docker Instructions

These are instructions to build and use a docker image for running a SageCell service in production.

## Build and Run the Docker Image

Execute the following command from the `sagecell-docker` directory.

```bash
docker build -t sagecell .
```

Then run the container by executing the following command in the `sagecell-docker` directory.

```bash
docker run --rm -p 127.0.0.1:3500:3500 sagecell:latest
```

Note that the `-p` argument exposes port `3500` inside the container to port `3500` outside the container, but only
allows connections from localhost. This is important as it does not allow anyone else to use the SageCell service other
than the local webwork server. If a different port outside the container is needed, then change the first `3500` to the
desired port. Adding `--rm` removes the created volume for the container when it exits. Exit the container by typing
`Ctrl-C`.

Access by specific external IP addresses is also possible if you want to have the SageCell service on another server.
The easiest way to accomplish this is by using an SSH tunnel. For example, execute
`ssh -L 3500:127.0.0.1:3550 userId@sagecell.server` where `userId` is your username on the SageCell server and
`sagecell.server` is the domain name or IP address of the SageCell server. There are other ways to accomplish this as
well, but the important thing is that access to the SageCell service be highly restricted as it allows untrusted code to
be executed.

## Deploy the Image for Production Usage

Copy the file `sagecell-docker.dist.service` to `sagecell-docker.service` and execute the following command from the
`sagecell-docker` directory to enable a `systemd` service for running the container.

```bash
sudo systemctl enable $(pwd)/sagecell-docker.service
```

Then you can start the container by executing `sudo systemctl start sagecell-docker`, and stop the container by
executing `sudo systemctl stop sagecell-docker`. Note that any time the server is rebooted the service will start
automatically, so you usually do not need to execute those commands other than to start the service the first time after
enabling it.

Note that the service simply executes the command give above for running the container directly. So modify the command
in the `sagecell-docker.service` file as described above if a different port is needed.
