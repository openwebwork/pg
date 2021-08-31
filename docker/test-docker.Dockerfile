FROM perl:5.32
# install needed perl modules
RUN cpanm -fi --notest \
  Class::Accessor \
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
# RUN echo "cp -f /opt/webwork/pg/conf/pg_defaults.yml.dist /opt/webwork/pg/conf/pg_defaults.yml" >> ~/.bashrc
WORKDIR /opt/webwork/pg
ENV PG_ROOT /opt/webwork/pg
# ENV WEBWORK_ROOT /opt/webwork/webwork2
# ENV WEBWORK_TOPLEVEL /opt/webwork
# ENV HARNESS_PERL_SWITCHES -MDevel::Cover
CMD ["/bin/bash"]
