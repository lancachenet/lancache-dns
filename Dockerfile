FROM alpine:latest
MAINTAINER SteamCache.Net Team <team@steamcache.net>

RUN	apk update \
	&& apk add dnsmasq

COPY root/ /

EXPOSE 53/udp

ENTRYPOINT [ "/scripts/bootstrap.sh" ]
