FROM perl:latest
# set metadata
LABEL maintainer="fabian.gabel@tuhh.de"
LABEL hub.docker.com="eltenedor/pg-unit-testing"
# install needed perl modules
RUN cpanm -fi --notest \
  Data::Dump \
  Date::Parse \
  DateTime \
  Devel::Cover \
  Devel::Cover::Report::Codecov \
  HTML::Entities \
  HTML::TagParser \
  JSON \
  Module::Build \
  Test::Exception \
  Tie::IxHash \
  UUID::Tiny module
# create webwork environment
RUN \
  mkdir -p /opt/webwork
WORKDIR /opt/webwork
ENV WEBWORK_ROOT /opt/webwork/webwork2
ENV PG_ROOT /opt/webwork/pg
#ENV HARNESS_PERL_SWITCHES -MDevel::Cover
CMD ["/bin/bash"]
