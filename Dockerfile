FROM alpine:latest
MAINTAINER SteamCache.Net Team <team@steamcache.net>

ENV STEAMCACHE_DNS_VERSION=1 ENABLE_DNSSEC_VALIDATION=false LANCACHE_DNSDOMAIN=cache.steamcache.net

RUN	apk update && apk add			\
		bind	\
		bash	\
		jq		\
		curl	\
		git

COPY	overlay/ /

RUN	mkdir -p /var/cache/bind /var/log/named		\
	&& chmod 755 /scripts/*				\
	&& chown named:named /var/cache/bind /var/log/named


EXPOSE 53/udp

WORKDIR /scripts

RUN git clone https://github.com/uklans/cache-domains/ /opt/cache-domains

CMD ["bash", "/scripts/bootstrap.sh"]
