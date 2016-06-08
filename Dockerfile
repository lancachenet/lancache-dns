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

ENV STEAMCACHE_IP 10.0.0.3
ENV BLIZZARDCACHE_IP 10.0.0.4
ENV FRONTIERCACHE_IP 10.0.0.4
ENV ORIGINCACHE_IP 10.0.0.4
ENV RIOTCACHE_IP 10.0.0.4
ENV UPLAYCACHE_IP 10.0.0.4
ENV WINDOWSCACHE_IP 10.0.0.4

ENTRYPOINT ["/scripts/bootstrap.sh"]
