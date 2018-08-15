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


if ! [ -z "${USE_GENERIC_CACHE}" ]; then
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

echo "Bootstrapping DNS from https://github.com/uklans/cache-domains"

if ! [ -z "${USE_GENERIC_CACHE}" ]; then
    echo ""
    echo "----------------------------------------------------------------------"
    echo "Using Generic Server: ${LANCACHE_IP}"
    echo "Make sure you are using a load balancer at ${LANCACHE_IP}"
    echo "it is not recommended to use a single cache server for all services"
    echo "as you will get cache clashes."
    echo "----------------------------------------------------------------------"
    echo ""
fi

rm -f ${CACHECONF}
touch ${CACHECONF}

curl -s -o services.json https://raw.githubusercontent.com/uklans/cache-domains/master/cache_domains.json

cat services.json | jq -r '.cache_domains[] | .name, .domain_files[]' | while read L; do
  if ! echo ${L} | grep "\.txt" >/dev/null 2>&1 ; then
#    if [ "${L}" = "steam" ]; then
#      set -x
#    else
#      set +x
#    fi
    SERVICE=${L}
    SERVICEUC=`echo ${L} | tr [:lower:] [:upper:]`
    if ! env | grep "DISABLE_${SERVICEUC}=true" >/dev/null 2>&1; then
      if env | grep "${SERVICEUC}CACHE_IP" >/dev/null 2>&1; then
        C_IP=$(env | grep "${SERVICEUC}CACHE_IP=" | sed 's/.*=//')
      else
        C_IP=${LANCACHE_IP}
      fi
      if [ "$USE_GENERIC_CACHE" = "true" ] && ! [ -z "${C_IP}" ] ; then
        echo "Setting up ${SERVICE} -> ${C_IP}"
      else
        echo "Creating ${SERVICE} template"
      fi
      echo "## ${SERVICE}" >> ${CACHECONF}
    fi
  else

    if ! env | grep "DISABLE_${SERVICEUC}=true" >/dev/null 2>&1; then
      curl -s -o ${L} https://raw.githubusercontent.com/uklans/cache-domains/master/${L}
    	## files don't have a newline at the end
    	echo "" >> ${L}
    	cat ${L} | grep -v "^#" | while read URL; do
      	if [ "x${URL}" != "x" ] ; then
          ## remove the *. from the begging if it's there.
          URL=$(echo ${URL} | sed 's/^\*\.//;s/,//g')
          if ! grep "${URL}" ${CACHECONF} 1>/dev/null 2>&1; then
            if [ "$USE_GENERIC_CACHE" = "true" ] && ! [ -z "${C_IP}" ] ; then
              echo "zone \"${URL}\" in { type master; file \"/etc/bind/cache/${SERVICE}.db\";};" >> ${CACHECONF}
              cat ${ZONETEMPLATE} | sed "s/{{DATE}}/$(date +%Y%m%d%M)/;s/{{ service_ip }}/${C_IP}/g" > ${ZONEPATH}/${SERVICE}.db
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
  fi
done

rm services.json

echo ""
echo " --- "
echo ""

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

    env | grep -v LANCACHE_IP | grep "CACHE_IP" | while read SERVICE; do

        S=$(echo ${SERVICE} | sed 's/CACHE_IP.*//')
        I=$(env | grep "${S}CACHE_IP" | sed 's/.*=//')

        if ! [ -z "${S}" ] && ! [ -z "${I}" ]; then
            echo "Enabling ${S} on IP ${I}"
            enableService ${S} ${I}
        fi

    done
fi

if ! [ -z "${UPSTREAM_DNS}" ] ; then
  sed -i "s/#ENABLE_UPSTREAM_DNS#//;s/dns_ip/${UPSTREAM_DNS}/" /etc/bind/named.conf.options
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
