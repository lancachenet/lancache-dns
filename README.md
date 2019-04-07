# Steam Cache Docker Container

## Introduction

This docker container provides DNS entries for caching services to be used in conjunction with a steamcache/steamcache & steamcache/generic server.

The DNS is generated automatically at startup of the container, the list of supported services is available here: https://github.com/uklans/cache-domains

The primary use case is gaming events, such as LAN parties, which need to be able to cope with hundreds or thousands of computers receiving an unannounced patch - without spending a fortune on internet connectivity. Other uses include smaller networks, such as Internet Cafes and home networks, where the new games are regularly installed on multiple computers; or multiple independent operating systems on the same computer.

## Quick Explanation

For a LAN cache to function on your network you need two services.
* A depot cache service
* A special DNS service

The depot cache service transparently proxies your requests for content to Steam/Origin/Etc, or serves the content to you if it already has it.

The special DNS service handles DNS queries normally (recursively), except when they're about a cached service and in that case it responds that the depot cache service should be used.

## Usage

If all of the services you wish to run point to a single IP address, you should make sure you set USE_GENERIC_CACHE=true and set LANCACHE_IP to the IP address of the caching server.
In this case it is highly recommended that you use some form of load balancer or reverse proxy, as running a single caching server for multiple services will result in cache clashes and will result in incorrect or corrupt data.

Run the steamcache-dns container using the following to allow UDP port 53 (DNS) through the host machine:

```
docker run --name steamcache-dns -p 10.0.0.2:53:53/udp -e USE_GENERIC_CACHE=true -e LANCACHE_IP=10.0.0.3 steamcache/steamcache-dns:latest
```

You can specify a different IP for each service hosted within the cache for a full list os supported services have a look at https://github.com/uklans/cache-domains. Set the IP for a service using ${SERVICE}CACHE_IP environment:
```
LANCACHE_IP (requires USE_GENERIC_CACHE to be set to true)

BLIZZARDCACHE_IP
FRONTIERCACHE_IP
ORIGINCACHE_IP
RIOTCACHE_IP
STEAMCACHE_IP
UPLAYCACHE_IP
```

You can also disable any of the cache dns resolvers by setting the environment variable of DISABLE_${SERVICE}=true
```
DISABLE_BLIZZARD
DISABLE_RIOT
DISABLE_UPLAY

```

To use a custom upstream DNS server, use the `UPSTREAM_DNS` variable:

```
docker run --name steamcache-dns -p 10.0.0.2:53:53/udp -e STEAMCACHE_IP=10.0.0.3 -e UPSTREAM_DNS=8.8.8.8 steamcache/steamcache-dns:latest
```

This will add a forwarder for all queries not served by steamcache to be sent to the upstream DNS server, in this case Google's DNS.  If
you have a DNS server on 1.2.3.4, the command argument would be `-e UPSTREAM_DNS=1.2.3.4`.

## Custom Forks/Branches

If you have your own fork (or branch) forked from [uklans/cache-domains](https://github.com/uklans/cache-domains) and would like to use your own for testing purposes (before pushing it to the main branch) or cache from unofficially supported domains, then declare your username with `GITHUB_USERNAME` and your branch with `GITHUB_BRANCH` as so, for example:
```
docker run --name steamcache-dns -p 10.0.0.2:53:53/udp -e GITHUB_USERNAME="example-username" -e GITHUB_BRANCH="example-branch" steamcache/steamcache-dns:latest
```
giving that it would download the services and cache_domains.json from `https://github.com/example-username/uklans/example-branch`, and your new service, as a variable, would be `<SERVICE_NAME>CACHE_IP` from `<SERVICE_NAME>.txt`

## Multiple IPs

Should you wish a cache server to have multiple IP addresses (for example a monolithic instance tuned for steam) you may specify them as a space delimited list within quotes for example: `-e STEAMCACHE_IP="1.2.3.4 5.6.7.8"`

## Running on Startup

Follow the instructions in the Docker documentation to run the container at startup.
[Documentation](https://docs.docker.com/config/containers/start-containers-automatically/)

## Further information

More information can be found at the [SteamCache github page](http://steamcache.net)

## License

The MIT License (MIT)

Copyright (c) 2015-2017 Jessica Smith, Robin Lewis, Brian Wojtczak, Jason Rivers, James Kinsman

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
