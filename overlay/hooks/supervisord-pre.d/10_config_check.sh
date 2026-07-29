#!/bin/bash
set -e

echo "Checking Bind9 config"

if ! named-checkconf /etc/bind/named.conf; then
	echo "Problem with Bind9 configuration - Bailing" >&2
	exit 1
fi
