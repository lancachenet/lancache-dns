FROM golang:1.17.2-alpine AS builder-dnstool

WORKDIR /go/src/

RUN \
echo ">> Downloading required apk's..." && \
apk --no-cache add git

RUN \
echo ">> Clone dnstool repo..." && \
git clone https://github.com/nightah/dnstool.git .

RUN \
echo ">> Starting go build..." && \
CGO_ENABLED=0 go build -trimpath

FROM lancachenet/ubuntu:latest
MAINTAINER LanCache.Net Team <team@lancache.net>

ENV STEAMCACHE_DNS_VERSION=1 ENABLE_DNSSEC_VALIDATION=false LANCACHE_DNSDOMAIN=cache.lancache.net CACHE_DOMAINS_REPO=https://github.com/uklans/cache-domains.git CACHE_DOMAINS_BRANCH=master UPSTREAM_DNS=8.8.8.8
RUN apt-get update && apt-get install -y bind9 curl dnsutils git

COPY overlay/ /
COPY --from=builder-dnstool /go/src/dnstool /hooks/entrypoint-pre.d/10_generate_config

RUN	mkdir -p /var/cache/bind /var/log/named		\
	&& chown bind:bind /var/cache/bind /var/log/named

RUN git clone --depth=1 --no-single-branch https://github.com/uklans/cache-domains/ /opt/cache-domains

EXPOSE 53/udp
EXPOSE 53/tcp

WORKDIR /scripts

