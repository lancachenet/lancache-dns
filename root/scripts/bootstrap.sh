#!/bin/sh
set -e

mkdir -p /data/logs

/scripts/generate_config.sh

dnsmasq --test
dnsmasq -k --log-facility=/data/logs/dnsmasq.log --log-queries
