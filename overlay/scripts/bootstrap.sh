#/bin/bash

set -e

ZONEPATH="/etc/bind/cache/"
ZONETEMPLATE="/etc/bind/cache/zone.tmpl"
CACHECONF="/etc/bind/cache.conf"

echo "     _                                      _                       _   "
echo "    | |                                    | |                     | |  "
echo " ___| |_ ___  __ _ _ __ ___   ___ __ _  ___| |__   ___   _ __   ___| |_ "
echo "/ __| __/ _ \\/ _\` | '_ \` _ \\ / __/ _\` |/ __| '_ \\ / _ \\ | '_ \\ / _ \\ __|"
echo "\\__ \\ ||  __/ (_| | | | | | | (_| (_| | (__| | | |  __/_| | | |  __/ |_ "
echo "|___/\\__\\___|\\__,_|_| |_| |_|\\___\\__,_|\\___|_| |_|\\___(_)_| |_|\\___|\\__|"
echo ""
echo ""

echo "Bootstrapping DNS from https://github.com/uklans/cache-domains"

if ! [ -z "${USE_GENERIC_CACHE}" ]; then
    echo "Using Generic Server: ${LANCACHE_IP}"
    echo "Make sure you are using a load balancer at ${LANCACHE_IP}, it is not recommended to use a single cache server for all services as you will get cache clashes."
fi

rm -f ${CACHECONF}
touch ${CACHECONF}

curl -s -o services.json https://raw.githubusercontent.com/uklans/cache-domains/master/cache_domains.json

cat services.json | jq -r '.cache_domains[] | .name, .domain_files[]' | while read L; do


    if ! echo ${L} | grep "\.txt" >/dev/null 2>&1 ; then
      SERVICE=${L}
      SERVICEUC=`echo ${L} | tr [:lower:] [:upper:]`
      echo "setting up ${SERVICE}"
      echo "## ${SERVICE}" >> ${CACHECONF}
    else

	curl -s -o ${L} https://raw.githubusercontent.com/uklans/cache-domains/master/${L}
	## files don't have a newline at the end
	echo "" >> ${L}
	cat ${L} | grep -v "^#" | while read URL; do

	if [ "x${URL}" != "x" ] ; then
        ## remove the *. from the begging if it's there.
        URL=$(echo ${URL} | sed 's/^\*\.//;s/,//g')
        if ! grep "${URL}" ${CACHECONF} 1>/dev/null 2>&1; then
            if [ "$USE_GENERIC_CACHE" = "true" ] && ! [ -z "${LANCACHE_IP}" ] ; then
                echo "zone \"${URL}\" in { type master; file \"/etc/bind/cache/${SERVICE}.db\";};" >> ${CACHECONF}
                cat ${ZONETEMPLATE} | sed "s/{{DATE}}/$(date +%Y%m%d%M)/;s/{{ service_ip }}/${LANCACHE_IP}/g" > ${ZONEPATH}/${SERVICE}.db
            else
                echo "#ENABLE_${SERVICEUC}#zone \"${URL}\" in { type master; file \"/etc/bind/cache/${SERVICE}.db\";};" >> ${CACHECONF}
                cat ${ZONETEMPLATE} | sed "s/{{DATE}}/$(date +%Y%m%d%M)/;s/{{ service_ip }}/{{ ${SERVICE}_ip }}/g" > ${ZONEPATH}/${SERVICE}.db
            fi
        fi
	fi
	done
    echo "" >> ${CACHECONF}
    rm ${L}
    fi

done

rm services.json

enableService() {
    SERVICE=$1
    SERVICE_IP=$2

    SERVICE_LC=`echo ${SERVICE} | tr [:upper:] [:lower:]`
    ZONEFILE="/etc/bind/cache/${SERVICE_LC}.db"
    echo "creating ${ZONEFILE}"

    if ! [ -z "$SERVICE_IP" ]; then
        sed -i -e "s%{{ ${SERVICE_LC}_ip }}%${SERVICE_IP}%g" ${ZONEFILE}
        sed -i -e "s%#ENABLE_${SERVICE}#%%g" ${CACHECONF}
    fi
}
if [ -z "$USE_GENERIC_CACHE" ]; then

    env | grep "ENABLE" | while read SERVICE; do

        S=$(echo ${SERVICE} | sed 's/ENABLE_//;s/=.*//')
        I=$(env | grep "${S}_IP" | sed 's/.*=//')

        if ! [ -z "${S}" ] && ! [ -z "${I}" ]; then
            echo "Enabling ${S} on IP ${I}"
            enableService ${S} ${I}
        fi

    done
fi


echo "finished bootstrapping."

echo "checking Bind9 config"

if ! /usr/sbin/named-checkconf /etc/bind/named.conf ; then
    echo "Problem with Bind9 configuration - Bailing" >&2
    exit 1
fi

echo "Running Bind9"

/usr/sbin/named -u named -c /etc/bind/named.conf -f
BEC=$?

if ! [ $BEC = 0 ]; then
    echo "Bind9 exited with ${BEC}"
    exit ${BEC} #exit with the same exit code as bind9
fi
