FROM alpine:latest
MAINTAINER SteamCache.Net Team <team@steamcache.net>

ENV STEAMCACHE_DNS_VERSION 1

RUN	apk update			\
	&& apk add bind		

COPY	overlay/ /

RUN	mkdir -p /var/cache/bind /var/log/named		\
	&& chmod 755 /scripts/*				\
	&& chown named:named /var/cache/bind /var/log/named


EXPOSE 53/udp

WORKDIR /scripts

ENTRYPOINT ["/scripts/bootstrap.sh"]
