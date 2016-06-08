#!/bin/sh

# if [ -n "$STEAMCACHE_RESOLVE_NAME" ]
# then
# 	RESOLVED_IP="$(nslookup "$STEAMCACHE_RESOLVE_NAME" 2>/dev/null | grep 'Address' | awk '{ print $3 }')"
# 	if [ -n "$RESOLVED_IP" ]
# 	then
# 		echo "Resolved ${STEAMCACHE_RESOLVE_NAME} to ${RESOLVED_IP}"
# 		STEAMCACHE_IP="$RESOLVED_IP"
# 	else
# 		echo "Failed to resolve ${STEAMCACHE_RESOLVE_NAME}; using ${STEAMCACHE_IP} instead" >&2
# 	fi
# fi

# if [ -z "$STEAMCACHE_IP" ]
# then
# 	echo "No value in \$STEAMCACHE_IP!" >&2
# 	exit 1
# fi

echo "Running bootstrap.sh..."

## blizzard
cp /etc/bind/cache/blizzard/template.db.blizzard /etc/bind/cache/blizzard/db.blizzard

## frontier
cp /etc/bind/cache/frontier/template.db.frontier /etc/bind/cache/frontier/db.frontier


## origin
cp /etc/bind/cache/origin/template.db.origin /etc/bind/cache/origin/db.origin


## riot
cp /etc/bind/cache/riot/template.db.riot /etc/bind/cache/riot/db.riot


## steam
cp /etc/bind/cache/steam/template.db.content_.steampowered.com /etc/bind/cache/steam/db.content_.steampowered.com
cp /etc/bind/cache/steam/template.db.cs.steampowered.com /etc/bind/cache/steam/db.cs.steampowered.com


## uplay
cp /etc/bind/cache/uplay/template.db.uplay /etc/bind/cache/uplay/db.uplay


## windows
cp /etc/bind/cache/windows/template.db.windows /etc/bind/cache/windows/db.windows

sed -i -e "s%{{ blizzardcache_ip }}%$BLIZZARDCACHE_IP%g" /etc/bind/cache/blizzard/db.blizzard
sed -i -e "s%{{ frontiercache_ip }}%$FRONTIERCACHE_IP%g" /etc/bind/cache/frontier/db.frontier
sed -i -e "s%{{ origincache_ip }}%$ORIGINCACHE_IP%g" /etc/bind/cache/origin/db.origin
sed -i -e "s%{{ riotcache_ip }}%$RIOTCACHE_IP%g" /etc/bind/cache/riot/db.riot
sed -i -e "s%{{ steamcache_ip }}%$STEAMCACHE_IP%g" /etc/bind/cache/steam/db.content_.steampowered.com
sed -i -e "s%{{ steamcache_ip }}%$STEAMCACHE_IP%g" /etc/bind/cache/steam/db.cs.steampowered.com
sed -i -e "s%{{ uplaycache_ip }}%$UPLAYCACHE_IP%g" /etc/bind/cache/uplay/db.uplay
sed -i -e "s%{{ windowscache_ip }}%$WINDOWSCACHE_IP%g" /etc/bind/cache/windows/db.windows


echo "bootsrap finished."

/usr/sbin/named -u named -c /etc/bind/named.conf -f

sleep 1000
