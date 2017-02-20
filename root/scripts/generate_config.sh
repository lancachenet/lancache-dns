#!/bin/sh
set -e

if [ -z "$STEAMCACHE_IP" ]
then
 	echo "No value for \$STEAMCACHE_IP!" >&2
 	exit 1
fi

cat << EOF >> /etc/dnsmasq.d/steamcache.conf
# Steam
address=/cs.steampowered.com/$STEAMCACHE_IP
address=/content1.steampowered.com/$STEAMCACHE_IP
address=/content2.steampowered.com/$STEAMCACHE_IP
address=/content3.steampowered.com/$STEAMCACHE_IP
address=/content4.steampowered.com/$STEAMCACHE_IP
address=/content5.steampowered.com/$STEAMCACHE_IP
address=/content6.steampowered.com/$STEAMCACHE_IP
address=/content7.steampowered.com/$STEAMCACHE_IP
address=/content8.steampowered.com/$STEAMCACHE_IP
address=/steamcontent.com/$STEAMCACHE_IP

# Blizzard
address=/dist.blizzard.com.edgesuite.net/$STEAMCACHE_IP
address=/llnw.blizzard.com/$STEAMCACHE_IP
address=/dist.blizzard.com/$STEAMCACHE_IP
address=/blizzard.vo.llnwd.net/$STEAMCACHE_IP
address=/blzddist1-a.akamaihd.net/$STEAMCACHE_IP
address=/blzddist2-a.akamaihd.net/$STEAMCACHE_IP
address=/blzddist3-a.akamaihd.net/$STEAMCACHE_IP
address=/level3.blizzard.com/$STEAMCACHE_IP

# Frontier
address=/cdn.zaonce.net/$STEAMCACHE_IP

# Origin
address=/origin-a.akamaihd.net/$STEAMCACHE_IP
address=/cdn.ea.com/$STEAMCACHE_IP

# Riot
address=/l3cdn.riotgames.com/$STEAMCACHE_IP

# Uplay
address=/cdn.ubi.com/$STEAMCACHE_IP

# Windows
address=/download.windowsupdate.com/$STEAMCACHE_IP
EOF
