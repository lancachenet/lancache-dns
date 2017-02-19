#!/bin/sh
set -e

/scripts/generate_config.sh

dnsmasq --test
dnsmasq -k
