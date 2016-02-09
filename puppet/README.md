# PortAuthority

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with portauthority](#setup)
    * [What portauthority affects](#what-portauthority-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with portauthority](#beginning-with-portauthority)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
    * [Types](#types)
      * [pa_network](#pa_network)
      * [pa_service](#pa_service)
    * [Parser functions](#parser-functions)
      * [etcd_get](#etcd_get)
      * [etcd_get_keys](#etcd_get_keys)
      * [etcd_get_hash](#etcd_get_has)
5. [Limitations - OS compatibility, etc.](#limitations)

## Description

A module to provision the following:
- Highly-Available ETCD cluster
- Docker Engine
- Docker Swarm with ETCD as k/v store and HA Swarm Managers

Additional stuff can be done:
- create overlay networks
- run Docker containers

## Setup

### What portauthority affects

### Setup Requirements

### Beginning with portauthority

## Usage

## Reference

### Class definition

```
class{ 'portauthority':
  floating_ip        => '192.168.0.1',
  floating_ip_mask   => '255.255.255.0',
  floating_ip_iface  => 'eth0',
  cluster_members    => ['192.168.0.11','192.168.0.12','192.168.0.13'],
  private_registry   => 'my.private.registry',
  log_destination    => '192.168.0.100:5515',
  host_ip            => $::ipaddress_eth0,
  lb_image           => 'prozeta/pa-haproxy:latest',
  lb_name            => 'pa-loadbalancer',
  lb_log_destination => '192.168.0.100:5515',
  default_bridge_ip  => '192.168.255.1/24',
  gwbridge_network   => '192.168.254.0/24',
  gwbridge_address   => '192.168.254.1',
  dns                => ['8.8.8.8', '4.4.4.4'],
  swarm_tag          => 'latest',
}
```

Of course, you can use Hiera ;)

### Types

#### ```pa_network```

#### ```pa_service```

### Parser functions

#### ```etcd_get```

Returns a value of an ETCD key.

The function takes 3 arguments:
1. absolute key path (required)
2. array of hashes with keys ```host``` and ```port``` to define the cluster to connect to. Defaults to ```[ { host: lookupvar('fqdn'), port 2379 } ]```
3. timeout for ETCD requests in seconds. Defaults to ```3```.

```
$variable = etcd_get('/some/key')
```

#### ```etcd_get_keys```

Returns an Array of ETCD key names from a path.

The function takes 3 arguments:
1. absolute key path (required)
2. array of hashes with keys ```host``` and ```port``` to define the cluster to connect to. Defaults to ```[ { host: lookupvar('fqdn'), port 2379 } ]```
3. timeout for ETCD requests in seconds. Defaults to ```3```.

```
$variable = etcd_get_keys('/some')
```


#### ```etcd_get_hash```

Returns a Hash from ETCD path.

The function takes 3 arguments:
1. absolute key path (required)
2. array of hashes with keys ```host``` and ```port``` to define the cluster to connect to. Defaults to ```[ { host: lookupvar('fqdn'), port 2379 } ]```
3. timeout for ETCD requests in seconds. Defaults to ```3```.

```
$variable = etcd_get_hash('/')
```


## Limitations
