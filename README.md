# Docker Compose for a full-stack lancache.

![Docker Pulls](https://img.shields.io/docker/pulls/lancachenet/monolithic?label=Monolithic) ![Docker Pulls](https://img.shields.io/docker/pulls/lancachenet/lancache-dns?label=Lancache-dns) ![Docker Pulls](https://img.shields.io/docker/pulls/lancachenet/sniproxy?label=Sniproxy) ![Docker Pulls](https://img.shields.io/docker/pulls/lancachenet/generic?label=Generic)

This docker-compose is meant as an example for running our lancache stack, It will run out of the box with minimal changes to the `.env` file for your local IP address and disk settings.

Once (and only once) you have a working system run `sudo ./enable_autostart.sh` to allow the containers to run at system startup

# Settings
> You *MUST* set at least `LANCACHE_IP` and `DNS_BIND_IP`. It is highly recommended that you change `CACHE_ROOT` to a folder of your choosing, and set [`CACHE_DISK_SIZE`](#cache_disk_size) to a value that suits your storage capacity.

## `USE_GENERIC_CACHE`
This controls IP assignment within the DNS service - it assumes that every service is reachable by default on every IP given in `LANCACHE_IP`. See the [lancache-dns](https://github.com/lancachenet/lancache-dns) project for documentation on customising the behaviour of the DNS service.

## `LANCACHE_IP`
This provides one or more IP addresses to the DNS service to advertise the cached services. If your cache host has exactly one IP address (e.g. `192.168.0.10`), specify that here. If your cache host has more IP addresses, you can list all of them, separated by spaces (e.g. `192.168.0.10 192.168.0.11 192.168.0.12`) - DNS entries will be configured for all services and all IPs by default.

> **Note:** unless your cache host is at `10.0.39.1`, you will want to change this value.

## `DNS_BIND_IP`
This sets the IP address that the DNS service will listen on. If your cache host has exactly one IP address (eg. `192.168.0.10`), specify that here. If your cache host has multiple IPs, specify exactly one and use that. This compose stack does not support the DNS service listening on multiple IPs by default.

> **Note:** unless your cache host is at `10.0.39.1`, you will want to change this value.

There are a few ways to make your local network aware of the cache server.

1. Advertise the IP given in `DNS_BIND_IP` via DHCP to your network as a nameserver. In this scenario, all clients configured to use the nameservers from DNS will use the `lancache-dns` service.
  This allows the `lancache-dns` service to provide clients with the appropriate local IPs for cached services, and all other requests will be passed to `UPSTREAM_DNS`.
2. Use the configuration generators available from [UKLANs' cache-domains](https://github.com/uklans/cache-domains) project to create configuration data to load into your network's existing DNS infrastructure

## `METRIC_BIND_IP`
This sets the IP address that the metric services will listen on. If your cache host has exactly one IP address 
(eg. `192.168.0.10`), specify that here. If your cache host has multiple IPs, specify exactly one and use that.

This may be used to segregate the cache and dns ip endpoints from the metrics endpoints.

For prometheus to scrape the metrics, you will need to add the following to your prometheus.yml file:

> Please note, that Prometheus is not included in this docker-compose stack.

```yaml
scrape_configs:
  - job_name: 'lancache'
    static_configs:
      - targets: ['<METRIC_BIND_IP>:<METRIC_PORT>']
```

- `<METRIC_BIND_IP>` is the IP address you set in the `METRIC_BIND_IP` environment variable
- `<METRIC_PORT>` is the port of the metric services. Please see below for the ports used by the metric services.

| Service    | Port |
|------------|------|
| Bind (DNS) | 9119 |
| Monolithic | 9113 |

### Prometheus example

The following is a full example of a prometheus.yml file that will scrape the metrics from the lancache services.

```yaml
scrape_configs:
  - job_name: 'lancache-dns'
    static_configs:
      - targets: ['192.168.0.10:9119']
  - job_name: 'lancache-monolithic'
    static_configs:
      - targets: ['192.168.0.10:9113']
```


## `UPSTREAM_DNS`
This allows you to choose one or more IP addresses for upstream DNS resolution if a name is not matched by the `lancache-dns` service (e.g. non-cached services, local hostname resolution).

Whichever resolver you choose depends on your network's requirements - if you don't need to provide internal DNS names, you can point `UPSTREAM_DNS` directly to an external resolver (the default is Google's DNS at `8.8.8.8`).

If you run internal services on your network, you can set `UPSTREAM_DNS` to be your internal DNS resolver(s), semicolon separated (e.g. `192.168.0.1; 192.168.0.2`).

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

> **Note:** this setting defaults to `./lancache`. Unless your cache storage lives here, you probably want to change this value.

## `CACHE_DISK_SIZE`
This setting will constrain the upper limit of space used by cached data.
The cache server will automatically delete cached data when the total stored amount approaches this limit, in a least-recently-used fashion (oldest data, least accessed deleted first).

> **Note:** that this must be given in either:
> - gigabytes, with `g` suffix (e.g. the default value, `2000g`)
> - terabytes, with `t` suffix (e.g. `4t`)

## `MIN_FREE_DISK`
Configures the minimum amount of free disk space that must be kept at all times.  This setting avoids the scenario where the disk can accidentally become completely full, and no further data can be written.

When the available free space drops below the set amount for any reason, the cache server will begin pruning content in a least-recently-used fashion, similar to how `CACHE_DISK_SIZE` works.

## `CACHE_INDEX_SIZE`
Change this to allow sufficient index memory for the nginx cache manager (default 500m)
We recommend 250m of index memory per 1TB of CACHE_DISK_SIZE

> **Note:** this setting does not limit the amount of memory that the Linux host will use for page caches, only what the cache server will use itself - see the Docker documentation on limiting memory consumption for a container if you wish to constrain the total memory consumption of the cache server, but generally you want as much memory as possible on your cache server to be used to store hot data.

## `CACHE_MAX_AGE`
This setting allows you to control the maximum duration cached data will be kept for. The default should be fine for most use cases - the `CACHE_DISK_SIZE` setting will generally be used before this for aging out data.

> **Note:** this must be given as a number of days in age before expiry, with a `d` suffix (e.g. the default value, `3650d`).

## `TZ`
This setting allows you to set the timezone that is used by the docker containers. Most notably changing the timestamps of the logs. Useful for debugging without having to think sometimes multiple hours in the future/past.

For a list of all timezones see https://en.wikipedia.org/wiki/List_of_tz_database_time_zones.

# More information
The LanCache docker-stack is generated automatically from the data over at [UKLans](https://github.com/uklans/cache-domains). All services that are listed in the UKLans repository are available and supported inside this docker-compose.

For an FAQ see https://lancache.net/docs/faq/
