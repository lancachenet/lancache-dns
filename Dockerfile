FROM alpine:latest
MAINTAINER SteamCache.Net Team <team@steamcache.net>

ENV STEAMCACHE_DNS_VERSION 1

RUN	apk update \
	&& apk add dnsmasq

COPY root/ /

EXPOSE 53/udp

WORKDIR /scripts

ENTRYPOINT ["/scripts/bootstrap.sh"]
