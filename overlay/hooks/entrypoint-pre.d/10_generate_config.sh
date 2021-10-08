#/bin/bash

set -e

ZONEPATH="/etc/bind/cache/"
ZONETEMPLATE="/etc/bind/cache/zone.tmpl"
CACHECONF="/etc/bind/cache.conf"
USE_GENERIC_CACHE="${USE_GENERIC_CACHE:-false}"
LANCACHE_DNSDOMAIN="${LANCACHE_DNSDOMAIN:-cache.lancache.net}"
CACHE_ZONE="${ZONEPATH}$LANCACHE_DNSDOMAIN.db"
RPZ_ZONE="${ZONEPATH}rpz.db"
CUSTOM_ZONE="${ZONEPATH}custom.db"
DOMAINS_PATH="/opt/cache-domains"
UPSTREAM_DNS=${UPSTREAM_DNS:-8.8.8.8}
MAX_DNSCACHE_TTL=${MAX_DNSCACHE_TTL}
MAX_DNSNCACHE_TTL=${MAX_DNSNCACHE_TTL}
FORWARD_ONLY=${FORWARD_ONLY}

reverseip () {       
    local IFS        
    IFS=.            
    set -- $1        
    echo $4.$3.$2.$1 
}                    

if ! [ -z "${UPSTREAM_DNS}" ] ; then
  echo "configuring /etc/resolv.conf to stop from looping to ourself"
  echo "# Lancache dns config" > /etc/resolv.conf
  for ns in $(echo $UPSTREAM_DNS | sed "s/[;]/ /g")
  do
      # call your procedure/other scripts here below
      echo "nameserver $ns" >> /etc/resolv.conf
  done
fi
echo ""

echo "Bootstrapping Lancache-DNS from ${CACHE_DOMAINS_REPO}"

export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
pushd ${DOMAINS_PATH} > /dev/null
if [[ ! -d .git ]]; then
	git clone ${CACHE_DOMAINS_REPO} .
fi

if [[ "${NOFETCH:-false}" != "true" ]]; then
	# Disable error checking whilst we attempt to get latest
	set +e
	git remote set-url origin ${CACHE_DOMAINS_REPO}
	git fetch origin || echo "Failed to update from remote, using local copy of cache_domains"
	git reset --hard origin/${CACHE_DOMAINS_BRANCH}
	# Reenable error checking
	set -e
fi
popd > /dev/null

if [ "$USE_GENERIC_CACHE" = "true" ]; then
  if [ -z "${LANCACHE_IP}" ]; then
    echo "If you are using USE_GENERIC_CACHE then you must set LANCACHE_IP"
    exit 1
  fi
else
  if ! [ -z "${LANCACHE_IP}" ]; then
    echo "If you are using LANCACHE_IP then you must set USE_GENERIC_CACHE=true"
    exit 1
  fi
fi

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

#Generate the SOA for cache.lancache.net

echo "\$ORIGIN $LANCACHE_DNSDOMAIN. 
\$TTL    600
@       IN  SOA localhost. dns.lancache.net. (
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

cp ${DOMAINS_PATH}/cache_domains.json ./services.json

cat services.json | jq -r '.cache_domains[] | .name, .domain_files[]' | while read L; do
  if ! echo ${L} | grep "\.txt" >/dev/null 2>&1 ; then
    SERVICE=${L}
    # Uppercase service, strip non-alphanumeric characters and replace with underscores
    SERVICEUC=`echo ${L} | sed 's/[^a-z0-9]\+/_/g' | tr [:lower:] [:upper:]`
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
      		echo ";## ${SERVICE}" >> ${RPZ_ZONE}
			for IP in $C_IP; do
				echo "$SERVICE IN A $IP;" >> $CACHE_ZONE
				echo "32.$(reverseip $IP).rpz-client-ip      CNAME rpz-passthru.;" >> ${RPZ_ZONE}
			done
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

        cp ${DOMAINS_PATH}/${L} ./${L}
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

if ! [ -z "${PASSTHRU_IPS}" ]; then                                                     
  for IP in ${PASSTHRU_IPS}; do                                                       
    echo ";## Additional RPZ passthroughs"                                          
    echo "32.$(reverseip $IP).rpz-client-ip      CNAME rpz-passthru." >> ${RPZ_ZONE}
  done                                                                                
fi       

# Ensure there is a file for BIND to see, even if it's empty
if [ ! -f "$CUSTOM_ZONE" ]; then
   touch $CUSTOM_ZONE;
fi

# Add line for custom domains
echo "\$INCLUDE $CUSTOM_ZONE" >> ${RPZ_ZONE}

if ! [ -z "${UPSTREAM_DNS}" ] ; then
  sed -i "s/#ENABLE_UPSTREAM_DNS#//;s/dns_ip/${UPSTREAM_DNS}/" /etc/bind/named.conf.options
fi

if [ "${ENABLE_DNSSEC_VALIDATION}" = true ] ; then
	echo "Enabling dnssec validation"
	sed -i "s/dnssec-validation no/dnssec-validation auto/" /etc/bind/named.conf.options
fi

if ! [ -z "${MAX_DNSCACHE_TTL}" ] ; then
  if [ [ ! [ "${FORWARD_ONLY}" = true ] ] && [ ${MAX_DNSCACHE_TTL} == 0 ] ] ; then
    sed -i "s/#ENABLE_MAX_DNSCACHE_TTL#/max-cache-ttl ${MAX_DNSCACHE_TTL};/" /etc/bind/named.conf.options
  else
    sed -i "s/#ENABLE_MAX_DNSCACHE_TTL#/max-cache-ttl 1;/" /etc/bind/named.conf.options #Enforce a minimum value if FORWARD_ONLY is not true.
  fi
else
  sed -i "s/#ENABLE_MAX_DNSCACHE_TTL#//" /etc/bind/named.conf.options
fi

if ! [ -z "${MAX_DNSNCACHE_TTL}" ] ; then
  sed -i "s/#ENABLE_MAX_DNSNCACHE_TTL#/max-ncache-ttl ${MAX_DNSNCACHE_TTL};/" /etc/bind/named.conf.options
else
  sed -i "s/#ENABLE_MAX_DNSNCACHE_TTL#//" /etc/bind/named.conf.options
fi

if [ "${FORWARD_ONLY}" = true ] ; then
  sed -i "s/#FORWARD_ONLY#/forward only;/" /etc/bind/named.conf.options
else
  sed -i "s/#FORWARD_ONLY#//" /etc/bind/named.conf.options
fi

echo "finished bootstrapping."
