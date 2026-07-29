FROM golang:1.23.1-alpine AS builder-dnstool

WORKDIR /go/src/

RUN <<EOF
echo ">> Downloading required apk's..."
apk --no-cache add git
EOF

RUN <<EOF
echo ">> Clone dnstool repo..."
git clone https://github.com/lancachenet/dnstool.git .
EOF

RUN <<EOF
echo ">> Starting go build..."
CGO_ENABLED=0 go build -trimpath -ldflags "-s -w"
EOF

# hadolint ignore=DL3007
FROM lancachenet/ubuntu:latest

LABEL org.opencontainers.image.authors="LanCache.Net Team <team@lancache.net>"

ENV \
  STEAMCACHE_DNS_VERSION=1 \
  ENABLE_DNSSEC_VALIDATION=false \
  LANCACHE_DNSDOMAIN=cache.lancache.net \
  CACHE_DOMAINS_REPO=https://github.com/uklans/cache-domains.git \
  CACHE_DOMAINS_BRANCH=master \
  UPSTREAM_DNS=8.8.8.8

# hadolint ignore=DL3008
RUN <<EOF
  apt-get update
  apt-get install -y bind9 ca-certificates curl dnsutils git --no-install-recommends
  apt-get -y clean
  rm -rf /var/lib/apt/lists/*
EOF

RUN  <<EOF
  mkdir -p /var/cache/bind /var/log/named
  chown bind:bind /var/cache/bind /var/log/named
EOF

RUN <<EOF
  git clone --depth=1 --no-single-branch https://github.com/uklans/cache-domains.git /opt/cache-domains
EOF

COPY --link overlay/ /
COPY --link --from=builder-dnstool /go/src/dnstool /usr/local/bin/dnstool

EXPOSE 53/udp
EXPOSE 53/tcp
WORKDIR /scripts
