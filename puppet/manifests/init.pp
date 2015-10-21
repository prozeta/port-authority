# == Class: portauthority
#
# Puppet module to bootstrap Port Authority infrastructure.
#
# === Parameters
#
# [*cluster_enabled*]
# [*cluster_members*]
# [*log_destination*]
# [*host_ip*]
# [*floating_ip*]
# [*docker_bridge_ip*]
# [*dns*]
# [*etcd_tag*]
# [*logger_tag*]
# [*registrator_tag*]
#
# === Variables
#
# === Examples
#
#  class { portauthority: }
#
# === Authors
#
# Radek 'blufor' Slavicinsky <radek@blufor.cz>
#

class portauthority (
  $cluster_enabled = false,
  $cluster_members = [],
  $log_destination = "",
  $host_ip = $::ipaddress_eth0,
  $floating_ip,
  $docker_bridge_ip = "192.168.168.1/24",
  $dns = ["8.8.8.8", "4.4.4.4"],
  $etcd_tag = "latest",
  $logger_tag = "latest",
  $registartor_tag = "latest",
) {
  class { "docker":
    dns => $dns,
    extra_parameters => "--bip ${docker_bridge_ip}",
    tcp_bind => "tcp://${host_ip}:4243",
  } ->

  class { "portauthority::images":
    etcd_tag => $etcd_tag,
    logger_tag => $logger_tag,
    registrator_tag => $registrator_tag,
  } ->

  class { "portauthority::services":
    cluster_enabled => $cluster_enabled,
    cluster_members => $cluster_members,
    log_destination => $log_destination,
    floating_ip => $floating_ip,
    host_ip => $host_ip,
  }

}
