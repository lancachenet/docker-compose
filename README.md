# Docker Compose for a full-stack lancache.

![Docker Pulls](https://img.shields.io/docker/pulls/lancachenet/monolithic?label=Monolithic) ![Docker Pulls](https://img.shields.io/docker/pulls/lancachenet/lancache-dns?label=Lancache-dns) ![Docker Pulls](https://img.shields.io/docker/pulls/lancachenet/sniproxy?label=Sniproxy) ![Docker Pulls](https://img.shields.io/docker/pulls/lancachenet/generic?label=Generic)

This docker-compose is meant as an example for running our lancache stack, It will run out of the box with minimal changes to the .env file for your local IP address.

# Settings
## `USE_GENERIC_CACHE`
This controls IP assignment within the DNS service - it assumes that every service is reachable by default on every IP given in `LANCACHE_IP`. See the [lancache-dns](https://github.com/lancachenet/lancache-dns) project for documentation on customising the behaviour of the DNS service.

## `LANCACHE_IP`
This provides one or more IP addresses to the DNS service to advertise the cached services. If your cache host has exactly one IP address (e.g. `192.168.0.10`), specify that here. If your cache host has more IP addresses, you can list all of them, separated by spaces (e.g. `192.168.0.10 192.168.0.11 192.168.0.12`) - DNS entries will be configured for all services and all IPs by default.

## `DNS_BIND_IP`
This sets the IP address that the DNS service will listen on. If your cache host has exactly one IP address (eg. `192.168.0.10`), specify that here. If your cache host has multiple IPs, specify exactly one and use that. This compose stack does not support the DNS service listening on multiple IPs by default.

There are a few ways to make your local network aware of the cache server.

1. Advertise the IP given in `DNS_BIND_IP` via DHCP to your network as a nameserver. In this scenario, all clients configured to use the nameservers from DNS will use the `lancache-dns` service.
  This allows the `lancache-dns` service to provide clients with the appropriate local IPs for cached services, and all other requests will be passed to `UPSTREAM_DNS`.
2. Use the configuration generators available from [UKLANs' cache-domains](https://github.com/uklans/cache-domains) project to create configuration data to load into your network's existing DNS infrastructure

## `UPSTREAM_DNS`
This allows you to choose one or more IP addresses for upstream DNS resolution if a name is not matched by the `lancache-dns` service (e.g. non-cached services, local hostname resolution).

Whichever resolver you choose depends on your network's requirements - if you don't need to provide internal DNS names, you can point `UPSTREAM_DNS` directly to an external resolver (the default is Google's DNS at `8.8.8.8`).

If you run internal services on your network, you can set `UPSTREAM_DNS` to be your internal DNS resolver(s).

**Note:** This setting should be exactly one IP until https://github.com/lancachenet/lancache-dns/issues/84 is fixed.

### Example external resolvers
- Google DNS:
  - `8.8.8.8`
  - `8.8.4.4`
- Cloudflare
  - `1.1.1.1`
- OpenDNS
  - `208.67.222.222`
  - `208.67.220.220`

## `CACHE_ROOT`
This will be used as the base directory for storing cached data (as `CACHE_ROOT/cache`) and logs (as `CACHE_ROOT/logs`).

The `CACHE_ROOT` should either be on a separate partition, or ideally on separate storage devices entirely, from your system root.

## `CACHE_MEM_SIZE`
This controls the size of the memory cache used by the cache server. The default should suffice for almost all configurations.

**Note:** this setting does not limit the amount of memory that the Linux host will use for page caches, only what the cache server will use itself - see the Docker documentation on limiting memory consumption for a container if you wish to constrain the total memory consumption of the cache server, but generally you want as much memory as possible on your cache server to be used to store hot data.

## `CACHE_DISK_SIZE`
This setting will constrain the upper limit of space used by cached data. You generally want to leave a small gap (10-20GB at least) between the size listed here and the available storage space used for the cached data, just in case.

The cache server will automatically cached data when the total stored amount approaches this limit, in a least-recently-used fashion (oldest data, least accessed deleted first).

## `CACHE_MAX_AGE`
This setting allows you to control the maximum duration cached data will be kept for. The default should be fine for most use cases - the `CACHE_DISK_SIZE` setting will generally be used before this for aging out data.

# More information
The LanCache docker-stack is generated automatically from the data over at [UKLans](https://github.com/uklans/cache-domains). All services that are listed in the UKLans repository are available and supported inside this docker-compose.

For an FAQ see https://github.com/lancachenet/monolithic/blob/master/faq.md
