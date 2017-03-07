FROM alpine:latest
MAINTAINER SteamCache.Net Team <team@steamcache.net>

RUN	apk update \
	&& apk add dnsmasq

COPY . /

EXPOSE 53/udp

ENTRYPOINT [ "steamcache-dns" ]
