$ORIGIN steamcontent.com.
$TTL	600
@		IN	SOA	ns1 dns.steamcache.net. (
			2016060800
			604800
			600
			600
			600 )
@		IN	NS	ns1
ns1		IN	A	{{ steamcache_ip }}
steamcache	IN	A	{{ steamcache_ip }}

*		IN	CNAME	steamcache.steamcontent.com.
*.steampipe	IN	CNAME	steamcache.steamcontent.com.
