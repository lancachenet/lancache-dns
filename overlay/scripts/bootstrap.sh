#!/bin/sh

cp /etc/bind/steamcache/template.db.content_.steampowered.com /etc/bind/steamcache/db.content_.steampowered.com
cp /etc/bind/steamcache/template.db.cs.steampowered.com /etc/bind/steamcache/db.cs.steampowered.com

sed -i -e "s%{{ steamcache_ip }}%$STEAMCACHE_IP%g" /etc/bind/steamcache/db.content_.steampowered.com
sed -i -e "s%{{ steamcache_ip }}%$STEAMCACHE_IP%g" /etc/bind/steamcache/db.cs.steampowered.com

/usr/sbin/named -u named -c /etc/bind/named.conf -f


sleep 10000
