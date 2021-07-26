FROM perl:latest
# set metadata
LABEL maintainer="fabian.gabel@tuhh.de"
LABEL hub.docker.com="eltenedor/pg-unit-testing"
# install needed perl modules
RUN cpanm -fi --notest \
  Data::Dump \
  Date::Parse \
  DateTime \
  Devel::Cover::Report::Codecov \
  HTML::Entities \
  HTML::TagParser \
  JSON \
  Module::Build Devel::Cover \
  Test::Exception \
  Tie::IxHash \
  UUID::Tiny module 
# create webwork environment
RUN \
  mkdir -p /opt/webwork && \
  git clone https://github.com/openwebwork/webwork2.git /opt/webwork/webwork2 && \
  cd /opt/webwork/webwork2/conf && \
  mv site.conf.dist site.conf && \
  mv localOverrides.conf.dist localOverrides.conf
WORKDIR /opt/webwork
ENV WEBWORK_ROOT /opt/webwork/webwork2
ENV PG_ROOT /opt/webwork/pg
CMD ["/bin/bash"]
