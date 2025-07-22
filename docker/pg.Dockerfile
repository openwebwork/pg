FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true
ENV DEBCONF_NOWARNINGS=yes

# Install dependencies
RUN apt-get update \
	&& apt-get install -y --no-install-recommends --no-install-suggests \
		cpanminus \
		dvipng \
		dvisvgm \
		imagemagick \
		libc6-dev \
		libclass-accessor-perl \
		libdbi-perl \
		libencode-perl \
		libgd-perl \
		libhtml-parser-perl \
		liblocale-maketext-lexicon-perl \
		libmojolicious-perl \
		libtest-mockobject-perl \
		libtest2-suite-perl \
		libtie-ixhash-perl \
		libuuid-tiny-perl \
		libyaml-libyaml-perl \
		make \
		pdf2svg \
		r-base-core \
		r-cran-rserve \
		texlive \
		texlive-latex-extra \
		texlive-latex-recommended \
		texlive-plain-generic \
	&& apt-get clean \
	&& cpanm -fi --notest HTML::TagParser \
	&& rm -fr /var/lib/apt/lists/* ./cpanm /root/.cpanm /tmp/*

RUN mkdir -p /opt/webwork

WORKDIR /opt/webwork/pg

ENV PG_ROOT=/opt/webwork/pg

ENTRYPOINT ["docker/entrypoint.sh"]

CMD ["/bin/bash"]
