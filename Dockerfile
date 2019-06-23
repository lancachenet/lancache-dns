FROM lancachenet/ubuntu:latest
MAINTAINER LanCache.Net Team <team@lancache.net>

ENV STEAMCACHE_DNS_VERSION=1 ENABLE_DNSSEC_VALIDATION=false LANCACHE_DNSDOMAIN=cache.lancache.net CACHE_DOMAINS_REPO=https://github.com/uklans/cache-domains.git UPSTREAM_DNS=8.8.8.8
RUN apt-get update && apt-get install -y bind9 jq curl dnsutils git

COPY overlay/ /

RUN	mkdir -p /var/cache/bind /var/log/named		\
	&& chown bind:bind /var/cache/bind /var/log/named

RUN git clone --depth=1 https://github.com/uklans/cache-domains/ /opt/cache-domains

EXPOSE 53/udp

WORKDIR /scripts

