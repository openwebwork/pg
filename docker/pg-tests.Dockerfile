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
  Test::Exception \
  Tie::IxHash \
  UUID::Tiny module \
  YAML::XS
# create webwork environment
# RUN \
#   mkdir -p /opt/webwork && \
#   git clone https://github.com/openwebwork/webwork2.git /opt/webwork/webwork2 && \
#   cd /opt/webwork/webwork2/conf && \
#   mv site.conf.dist site.conf && \
#   mv localOverrides.conf.dist localOverrides.conf
# RUN \
#   mkdir -p /opt/webwork/ \
#   ln -s . /opt/webwork/pg
WORKDIR /opt/webwork/pg

# # ENV WEBWORK_ROOT /opt/webwork/webwork2
ENV PG_ROOT /opt/webwork/pg
ENV HARNESS_PERL_SWITCHES -MDevel::Cover
# RUN cd ${PG_ROOT}/conf
# RUN cp pg_defaults.yml.dist pg_defaults.yml
CMD ["/bin/bash"]
