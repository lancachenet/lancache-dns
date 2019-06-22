FROM lancachenet/ubuntu:latest
MAINTAINER LanCache.Net Team <team@lancache.net>

ENV STEAMCACHE_DNS_VERSION=1 ENABLE_DNSSEC_VALIDATION=false LANCACHE_DNSDOMAIN=cache.lancache.net GITHUB_SOURCE="https://raw.githubusercontent.com/uklans/cache-domains/master" 
RUN apt-get update && apt-get install -y bind9 jq curl dnsutils

COPY	overlay/ /

RUN	mkdir -p /var/cache/bind /var/log/named		\
	&& chmod 755 /scripts/*				\
	&& chown bind:bind /var/cache/bind /var/log/named


EXPOSE 53/udp

WORKDIR /scripts

