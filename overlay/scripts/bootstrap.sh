#!/bin/sh

if [ -n "$STEAMCACHE_RESOLVE_NAME" ]
then
	RESOLVED_IP="$(nslookup "$STEAMCACHE_RESOLVE_NAME" 2>/dev/null | grep 'Address' | awk '{ print $3 }')"
	if [ -n "$RESOLVED_IP" ]
	then
		echo "Resolved ${STEAMCACHE_RESOLVE_NAME} to ${RESOLVED_IP}"
		STEAMCACHE_IP="$RESOLVED_IP"
	else
		echo "Failed to resolve ${STEAMCACHE_RESOLVE_NAME}; using ${STEAMCACHE_IP} instead" >&2
	fi
fi

if [ -z "$STEAMCACHE_IP" ]
then
	echo "No value in \$STEAMCACHE_IP!" >&2
	exit 1
fi

cp /etc/bind/steamcache/template.db.content_.steampowered.com /etc/bind/steamcache/db.content_.steampowered.com
cp /etc/bind/steamcache/template.db.cs.steampowered.com /etc/bind/steamcache/db.cs.steampowered.com

sed -i -e "s%{{ steamcache_ip }}%$STEAMCACHE_IP%g" /etc/bind/steamcache/db.content_.steampowered.com
sed -i -e "s%{{ steamcache_ip }}%$STEAMCACHE_IP%g" /etc/bind/steamcache/db.cs.steampowered.com

/usr/sbin/named -u named -c /etc/bind/named.conf -f


sleep 10000
