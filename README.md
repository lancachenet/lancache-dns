# Steam Cache Docker Container

## Introduction

This docker container provides DNS entries for \*.cs.steampowered.com to be used in conjunction with a steamcache server. 

The primary use case is gaming events, such as LAN parties, which need to be able to cope with hundreds or thousands of computers receiving an unannounced patch - without spending a fortune on internet connectivity. Other uses include smaller networks, such as Internet Cafes and home networks, where the new games are regularly installed on multiple computers; or multiple independent operating systems on the same computer.

## Usage

Run the steamcache-dns container using the following to allow UDP port 53 (DNS) through the host machine:

```
docker run --name steamcache-dns -p 10.0.0.2:53:53/udp -e STEAMCACHE_IP=10.0.0.3 steamcache/steamcache-dns:latest
```

The image needs to know the IP of the steamcache server, provide this via the STEAMCACHE_IP variable.
If you're also using the generic cache server, you should use USE_GENERIC_CACHE=true and set LANCACHE_IP variable.

Example running a steamcache + generic cache:
```
docker run --name steamcache-dns -p 10.0.0.2:53:53/udp -e STEAMCACHE_IP=10.0.0.3 -e USE_GENERIC_CACHE=true -e LANCACHE_IP=10.0.0.4 steamcache/steamcache-dns:latest
```

You can specify a different IP for each service hosted within the cache, with the following environment variables:
```
LANCACHE_IP (requires USE_GENERIC_CACHE to be set to true)

BLIZZARDCACHE_IP
FRONTIERCACHE_IP
ORIGINCACHE_IP
RIOTCACHE_IP
STEAMCACHE_IP
UPLAYCACHE_IP
WINDOWSCACHE_IP
```

You can also disable any of the cache dns resolvers by setting the following environment variables to "true"
```
DISABLE_BLIZZARD
DISABLE_FRONTIER
DISABLE_ORIGIN
DISABLE_RIOT
DISABLE_STEAM
DISABLE_UPLAY
DISABLE_WINDOWS

```


## Quick Explaination

For a steam cache to function on your network you need two services.
* A depot cache service
* A special DNS service

The depot cache service transparently proxies your requests for content to Steam, or serves the content to you if it already has it.

The special DNS service handles DNS queries normally (recursively), except when they're about Steam and in that case it responds that the depot cache service should be used.

## Running on Startup

Follow the instructions in the Docker documentation to run the container at startup.
[Documentation](https://docs.docker.com/articles/host_integration/)

## Further information

More information can be found at the [SteamCache github page](http://steamcache.net)

## License

The MIT License (MIT)

Copyright (c) 2015-2017 Jessica Smith, Robin Lewis, Brian Wojtczak, Jason Rivers

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
