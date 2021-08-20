FROM perl:latest
# set metadata
LABEL maintainer="fabian.gabel@tuhh.de"
LABEL hub.docker.com="eltenedor/pg-no-ww"
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
RUN mkdir -p /opt/webwork
# rename config file at startup 
RUN echo "cp -f /opt/webwork/pg/conf/pg_defaults.yml.dist /opt/webwork/pg/conf/pg_defaults.yml" >> ~/.bashrc
WORKDIR /opt/webwork
ENV PG_ROOT /opt/webwork/pg
ENV WEBWORK_ROOT /opt/webwork/webwork2
ENV HARNESS_PERL_SWITCHES -MDevel::Cover
CMD ["/bin/bash"]
