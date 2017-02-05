FROM debian:jessie
MAINTAINER michael@websr.eu
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -yqq --no-install-recommends \
	openssh-client \
	ca-certificates \
	lftp \
    davfs2 \
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
ENTRYPOINT ["/entrypoint.sh"]
CMD ["cron", "-f", "-L15"]
