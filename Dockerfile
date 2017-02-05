FROM debian:jessie
MAINTAINER michael@websr.eu

RUN apt-get update && apt-get install -y --no-install-recommends \
    rsyslog \
    git \
    cron \
    mysql-client \
    mongodb-clients

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ADD backup.sh /backup.sh
RUN chmod +x /backup.sh

RUN echo "Europe/Berlin" > /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata

WORKDIR /
VOLUME ["/backups"]
ENTRYPOINT ["/entrypoint.sh"]
CMD ["cron", "-f", "-L15"]
