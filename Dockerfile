FROM alpine:latest
MAINTAINER SteamCache.Net Team <team@steamcache.net>

ENV STEAMCACHE_DNS_VERSION=1 ENABLE_DNSSEC_VALIDATION=false

RUN	apk update && apk add			\
		bind	\
		bash	\
		jq		\
		curl	

COPY	overlay/ /

RUN	mkdir -p /var/cache/bind /var/log/named		\
	&& chmod 755 /scripts/*				\
	&& chown named:named /var/cache/bind /var/log/named


EXPOSE 53/udp

WORKDIR /scripts

CMD ["bash", "/scripts/bootstrap.sh"]
