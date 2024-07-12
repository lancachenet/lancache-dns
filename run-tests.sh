#!/bin/bash
which goss

if [ $? -ne 0 ]; then
	echo "Please install goss from https://goss.rocks/install"
	echo "For a quick auto install run the following"
	echo "curl -fsSL https://goss.rocks/install | sh"
	exit $?
fi

GOSS_WAIT_OPS="-r 60s -s 1s"

docker build --tag lancachenet/lancache-dns:goss-test .
case $1 in
  circleci)
    shift;
    mkdir -p ./reports/goss
	if [[ "$1" == "keepimage" ]]; then
		KEEPIMAGE=true
		shift
	fi
    export GOSS_OPTS="$GOSS_OPTS --format junit"
	dgoss run -e USE_GENERIC_CACHE=true -e STEAMCACHE_IP=10.0.0.2 -e LANCACHE_IP=10.0.0.1 -e UPSTREAM_DNS="8.8.8.8; 1.1.1.1" $@ lancachenet/lancache-dns:goss-test > reports/goss/report.xml
	#store result for exit code
	RESULT=$?
	#delete the junk that goss currently outputs :(
    sed -i '0,/^</d' reports/goss/report.xml
	#remove invalid system-err outputs from junit output so circleci can read it
	sed -i '/<system-err>.*<\/system-err>/d' reports/goss/report.xml
    ;;
  docker)
	shift;
	if [[ "$1" == "keepimage" ]]; then
		KEEPIMAGE=true
		shift
	fi
	dgoss edit -e USE_GENERIC_CACHE=true -e STEAMCACHE_IP=10.0.0.2 -e LANCACHE_IP=10.0.0.1 -e UPSTREAM_DNS="8.8.8.8; 1.1.1.1" $@ lancachenet/lancache-dns:goss-test
	RESULT=$?
    ;;
  edit)
	shift;
	if [[ "$1" == "keepimage" ]]; then
		KEEPIMAGE=true
		shift
	fi
	dgoss edit -e USE_GENERIC_CACHE=true -e STEAMCACHE_IP=10.0.0.2 -e LANCACHE_IP=10.0.0.1 -e UPSTREAM_DNS="8.8.8.8; 1.1.1.1" $@ lancachenet/lancache-dns:goss-test
	RESULT=$?
    ;;
  *)
	if [[ "$1" == "keepimage" ]]; then
		KEEPIMAGE=true
		shift
	fi
	dgoss run -e USE_GENERIC_CACHE=true -e STEAMCACHE_IP=10.0.0.2 -e LANCACHE_IP=10.0.0.1 -e UPSTREAM_DNS="8.8.8.8; 1.1.1.1" $@ lancachenet/lancache-dns:goss-test
	RESULT=$?
    ;;
esac
[[ "$KEEPIMAGE" == "true" ]] || docker rmi lancachenet/lancache-dns:goss-test

exit $RESULT
