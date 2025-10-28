ARG FPM_BASE
FROM ${FPM_BASE}

USER root

RUN apt-get -qq update && apt-get -qq install supervisor

ADD supervisord.conf /etc/supervisord.conf

RUN touch /var/log/supervisord.log && chmod 777 /var/log/supervisord.log

USER www-data

CMD ["/usr/bin/supervisord"]
