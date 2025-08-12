#!/bin/bash
set -e

echo ">> Setting DNSSEC cache domains..."
sed -i "s/\${ENABLE_DNSSEC_VALIDATION}/${ENABLE_DNSSEC_VALIDATION}/g" /etc/bind/named.conf.options
