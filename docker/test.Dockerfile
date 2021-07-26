FROM eltenedor/pg-unit-testing:latest
# # RUN mkdir -p /opt/webwork/pg
RUN cpanm --notest Devel::Cover Test::Exception HTML::TagParser
RUN cd /opt/webwork/pg
# RUN pwd
# RUN ls /opt/webwork/webwork2/conf
# RUN pwd
# RUN perl ./Build.PL
# RUN cover -test
ENV WEBWORK_ROOT /opt/webwork/webwork2
ENV PG_ROOT /opt/webwork/pg

CMD ["/bin/bash"]