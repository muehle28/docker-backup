FROM jessie:latest
MAINTAINER michael@websr.eu

RUN apt-get update && apt-get install -y \
    git \
    cron \
    mysql-client \
    mongodb-org-tools

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ADD backup.sh /backup.sh
RUN chmod +x /backup.sh

WORKDIR /
VOLUME ["/backups"]
ENTRYPOINT ["entrypoint.sh"]
CMD ["cron", "-f"]
