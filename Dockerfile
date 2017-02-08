FROM alpine:3.5
MAINTAINER michael@websr.eu

RUN \
apk add --no-cache jq && \
apk add --no-cache mysql-client && \
apk add --no-cache mongodb --repository http://dl-4.alpinelinux.org/alpine/edge/testing && \
apk add --no-cache mongodb-tools --repository http://dl-4.alpinelinux.org/alpine/edge/testing && \
apk add --no-cache tzdata

RUN /usr/bin/crontab -r

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ADD backup.sh /backup.sh
RUN chmod +x /backup.sh

RUN cp /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
echo "Europe/Berlin" > /etc/timezone  --frontend noninteractive tzdata && \
apk del tzdata

WORKDIR /
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/crond", "-f"]
