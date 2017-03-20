FROM alpine:latest
MAINTAINER SteamCache.Net Team <team@steamcache.net>

RUN	apk update \
	&& apk add dnsmasq

COPY overlay/ /

EXPOSE 53/udp

ENTRYPOINT [ "steamcache-dns" ]
