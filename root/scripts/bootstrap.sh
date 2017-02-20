#!/bin/sh
set -e

/scripts/generate_config.sh

dnsmasq --test
dnsmasq -k --log-facility=/dev/stdout --log-queries
