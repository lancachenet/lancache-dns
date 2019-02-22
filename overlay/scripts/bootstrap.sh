#/bin/bash

set -e

ZONEPATH="/etc/bind/cache/"
ZONETEMPLATE="/etc/bind/cache/zone.tmpl"
CACHECONF="/etc/bind/cache.conf"
USE_GENERIC_CACHE="${USE_GENERIC_CACHE:-false}"
LANCACHE_DNSDOMAIN="${LANCACHE_DNSDOMAIN:-cache.steamcache.net}"
CACHE_ZONE="${ZONEPATH}$LANCACHE_DNSDOMAIN.db"
RPZ_ZONE="${ZONEPATH}rpz.db"
GITHUB_USERNAME="${GITHUB_USERNAME:-uklans}"
GITHUB_BRANCH="${GITHUB_USERNAME:-master}"
GITHUB="$GITHUB_USERNAME/cache-domains/$GITHUB_BRANCH"

echo "     _                                      _                       _   "
echo "    | |                                    | |                     | |  "
echo " ___| |_ ___  __ _ _ __ ___   ___ __ _  ___| |__   ___   _ __   ___| |_ "
echo "/ __| __/ _ \\/ _\` | '_ \` _ \\ / __/ _\` |/ __| '_ \\ / _ \\ | '_ \\ / _ \\ __|"
echo "\\__ \\ ||  __/ (_| | | | | | | (_| (_| | (__| | | |  __/_| | | |  __/ |_ "
echo "|___/\\__\\___|\\__,_|_| |_| |_|\\___\\__,_|\\___|_| |_|\\___(_)_| |_|\\___|\\__|"
echo ""
echo ""
if ! [ -z "${UPSTREAM_DNS}" ] ; then
  echo "configuring /etc/resolv.conf to stop from looping to ourself"
  echo "nameserver ${UPSTREAM_DNS}" > /etc/resolv.conf
fi
echo ""



if [ "$USE_GENERIC_CACHE" = "true" ]; then
  if [ -z ${LANCACHE_IP} ]; then
    echo "If you are using USE_GENERIC_CACHE then you must set LANCACHE_IP"
    exit 1
  fi
else
  if ! [ -z ${LANCACHE_IP} ]; then
    echo "If you are using LANCACHE_IP then you must set USE_GENERIC_CACHE=true"
    exit 1
  fi
fi

echo "Bootstrapping DNS from https://github.com/$GITHUB"

if [ "$USE_GENERIC_CACHE" = "true" ]; then
    echo ""
    echo "----------------------------------------------------------------------"
    echo "Using Generic Server: ${LANCACHE_IP}"
    echo "Make sure you are using a monolithic cache or load balancer at ${LANCACHE_IP}"
    echo "----------------------------------------------------------------------"
    echo ""
fi

rm -f ${CACHECONF}
touch ${CACHECONF}

#Add the rpz zones to the cache.conf
echo "
	zone \"$LANCACHE_DNSDOMAIN\" {
		type master;
		file \"$CACHE_ZONE\";
	};
    zone \"rpz\" {
      type master;
      file \"$RPZ_ZONE\";
      allow-query { none; };
    };" > ${CACHECONF}

#Generate the SOA for cache.steamcache.net

echo "\$ORIGIN $LANCACHE_DNSDOMAIN. 
\$TTL    600
@       IN  SOA localhost. dns.steamcache.net. (
             $(date +%s)
             604800
             600
             600
             600 )
@       IN  NS  localhost.

" > $CACHE_ZONE

#Generate the RPZ zone file

echo "\$TTL 60
@            IN    SOA  localhost. root.localhost.  (
                          2   ; serial 
                          3H  ; refresh 
                          1H  ; retry 
                          1W  ; expiry 
                          1H) ; minimum 
                  IN    NS    localhost." > $RPZ_ZONE

curl -s -o services.json https://raw.githubusercontent.com/$GITHUB/cache_domains.json

cat services.json | jq -r '.cache_domains[] | .name, .domain_files[]' | while read L; do
  if ! echo ${L} | grep "\.txt" >/dev/null 2>&1 ; then
    SERVICE=${L}
    SERVICEUC=`echo ${L} | tr [:lower:] [:upper:]`
	echo "Processing service: $SERVICE"
	CONTINUE=false
	SERVICE_ENABLED=false
	if [ "$USE_GENERIC_CACHE" = "true" ]; then
    	if ! env | grep "DISABLE_${SERVICEUC}=true" >/dev/null 2>&1; then
			SERVICE_ENABLED=true	
		fi
	else
		echo "testing for presence of ${SERVICEUC}CACHE_IP"
    	if env | grep "${SERVICEUC}CACHE_IP" >/dev/null 2>&1; then
			SERVICE_ENABLED=true
		fi
	fi
	if [ "$SERVICE_ENABLED" == "true" ]; then
    	if env | grep "${SERVICEUC}CACHE_IP" >/dev/null 2>&1; then
    		C_IP=$(env | grep "${SERVICEUC}CACHE_IP=" | sed 's/.*=//')
    	else
    		C_IP=${LANCACHE_IP}
    	fi
		if [ "x$C_IP" != "x" ]; then
			echo "Enabling service with ip(s): $C_IP";
			for IP in $C_IP; do
				echo "$SERVICE IN A $IP;" >> $CACHE_ZONE
			done
      		echo ";## ${SERVICE}" >> ${RPZ_ZONE}
			CONTINUE=true
		else
			echo "Could not find IP for requested service: $SERVICE"
			exit 1
		fi
	else
		echo "Skipping $SERVICE"
	fi

  else
	if [ "$CONTINUE" == "true" ]; then

      curl -s -o ${L} https://raw.githubusercontent.com/$GITHUB/${L}
    	## files don't have a newline at the end
    	echo "" >> ${L}
		cat ${L} | grep -v "^#" | while read URL; do
      		if [ "x${URL}" != "x" ] ; then
				#RPZ entries do NOT need a trailing . on the rpz domain, but do for the redirect host
				echo "${URL} IN CNAME $SERVICE.$LANCACHE_DNSDOMAIN.;" >> $RPZ_ZONE;
      		fi
    	done
      rm ${L}
    fi
  fi
done

rm services.json

echo ""
echo " --- "
echo ""

if ! [ -z "${UPSTREAM_DNS}" ] ; then
  sed -i "s/#ENABLE_UPSTREAM_DNS#//;s/dns_ip/${UPSTREAM_DNS}/" /etc/bind/named.conf.options
fi

if [ "${ENABLE_DNSSEC_VALIDATION}" = true ] ; then
	echo "Enabling dnssec validation"
	sed -i "s/dnssec-validation no/dnssec-validation auto/" /etc/bind/named.conf.options
fi

echo "finished bootstrapping."

echo ""
echo " --- "
echo ""

echo "checking Bind9 config"

if ! /usr/sbin/named-checkconf /etc/bind/named.conf ; then
    echo "Problem with Bind9 configuration - Bailing" >&2
    exit 1
fi

echo "Running Bind9"

tail -F /var/log/named/general.log /var/log/named/default.log /var/log/named/queries.log  &

/usr/sbin/named -u named -c /etc/bind/named.conf -f
BEC=$?

if ! [ $BEC = 0 ]; then
    echo "Bind9 exited with ${BEC}"
    exit ${BEC} #exit with the same exit code as bind9
fi
