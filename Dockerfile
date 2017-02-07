FROM debian:jessie
MAINTAINER michael@websr.eu
ENV DEBIAN_FRONTEND noninteractive

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
RUN echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/3.4 main" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list

RUN apt-get update && apt-get install -yqq --no-install-recommends \
	openssh-client \
	ca-certificates \
	sshfs \
    davfs2 \
    cron \
    mysql-client \
    mongodb-org-shell \
    mongodb-org-tools

RUN mkdir /databackup

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ADD backup.sh /backup.sh
RUN chmod +x /backup.sh

RUN echo "Europe/Berlin" > /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata

WORKDIR /
ENTRYPOINT ["/entrypoint.sh"]
CMD ["cron", "-f", "-L15"]
