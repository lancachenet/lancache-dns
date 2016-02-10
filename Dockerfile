FROM alpine:latest
MAINTAINER SteamCache.Net Team <team@steamcache.net>

ENV STEAMCACHE_DNS_VERSION 1

RUN	apk update			\
	&& apk add bind		

COPY	overlay/ /

RUN	mkdir /var/cache/bind			\
	&& chmod 755 /scripts/*			\
	&& chown named:named /var/cache/bind


EXPOSE 53/udp

WORKDIR /scripts

ENV STEAMCACHE_IP 192.168.0.5

ENTRYPOINT ["/scripts/bootstrap.sh"]
