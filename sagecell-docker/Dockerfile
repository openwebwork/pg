FROM sagemath/sagemath:10.8

USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true
ENV DEBCONF_NOWARNINGS=yes

RUN apt-get update && apt-get install -y --no-install-recommends \
    automake \
    build-essential \
    curl \
    git \
    locales \
    openssh-server \
    python3 \
    python-is-python3 \
    python3-jupyter-client \
    python3-pip \
    python3-psutil \
    python3-zmq \
    rsyslog \
    wget \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen \
    && curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y --no-install-recommends --no-install-suggests nodejs

ENV SHELL=/bin/bash

USER sage

RUN echo "Installing SageCell server for SageMath" \
    && sage -pip install lockfile paramiko sockjs-tornado sqlalchemy \
    && git clone --single-branch --branch master --depth 1 https://github.com/sagemath/sagecell.git \
    && cd sagecell \
    && { sage -sh -c make || true; } \
    && sage -sh -c make \
    && rm -rf contrib doc tests .git \
    && cp config_default.py config.py \
    && sed -i 's/"username": None/"username": "sage"/' config.py \
	&& sed -i 's/requires_tos = True/requires_tos = False/' config.py

USER root

COPY sagecell-entrypoint.sh /usr/local/bin/sagecell-entrypoint

RUN echo "Configuring internal ssh server" \
    && chmod +x /usr/local/bin/sagecell-entrypoint \
    && echo "ListenAddress 127.0.0.1\nPasswordAuthentication no" \
        > /etc/ssh/sshd_config.d/sshd_config.conf

RUN echo "Cleaning the Container" \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

ENV PORT=3500

WORKDIR /home/sage/sagecell

ENTRYPOINT ["sagecell-entrypoint"]
CMD ["sudo", "-H", "-E", "-u", "sage", "sage", "web_server.py", "-p $PORT"]
