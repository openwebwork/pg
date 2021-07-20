FROM perl:latest
RUN cpanm -fi --notest \
  Data::Dump \
  Date::Parse \
  DateTime \
  JSON \
  Test::Exception \
  Tie::IxHash \
  UUID::Tiny module \
 && mkdir -p /opt/webwork
RUN git clone https://github.com/openwebwork/webwork2.git /opt/webwork/webwork2 && \
  cd /opt/webwork/webwork2/conf && \
  mv site.conf.dist site.conf && \
  mv localOverrides.conf.dist localOverrides.conf
WORKDIR /opt/webwork/pg
ENV WEBWORK_ROOT /opt/webwork/webwork2
ENV PG_ROOT /opt/webwork/pg
CMD ["/bin/bash"]
