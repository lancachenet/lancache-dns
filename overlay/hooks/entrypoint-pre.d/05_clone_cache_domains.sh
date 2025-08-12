#!/bin/bash
set -e

echo ">> Cloning/updating cache domains..."
if [ -d "/opt/cache-domains/.git" ]; then
    cd /opt/cache-domains
    git pull origin ${CACHE_DOMAINS_BRANCH}
else
    git clone --depth=1 -b ${CACHE_DOMAINS_BRANCH} ${CACHE_DOMAINS_REPO} /opt/cache-domains
fi