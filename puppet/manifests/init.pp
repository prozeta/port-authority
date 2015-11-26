# == Class: portauthority
#
# Puppet module to bootstrap Port Authority infrastructure.
#
# === Parameters
#
# [*cluster_enabled*]
# [*cluster_members*]
# [*private_registry*]
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
  $private_registry = '',
  $log_destination = '',
  $host_ip = $::ipaddress_eth0,
  $floating_ip,
  $docker_bridge_ip = '192.168.168.1/24',
  $dns = ['8.8.8.8', '4.4.4.4'],
  $etcd_tag = 'latest',
  $logger_tag = 'latest',
  $registrator_tag = 'latest',
) {
  if $portauthority::private_registry != '' {
    $registry_cfg = "--insecure_registry ${private_registry} "
  } else {
    $registry_cfg = ''
  }

  class { 'docker':
    dns              => $portauthority::dns,
    extra_parameters => "${registry_cfg} --bip ${portauthority::docker_bridge_ip}",
    tcp_bind         => "tcp://${portauthority::host_ip}:4243",
  } ->

  class { 'portauthority::images':
    etcd_tag        => $portauthority::etcd_tag,
    logger_tag      => $portauthority::logger_tag,
    registrator_tag => $portauthority::registrator_tag,
  } ->

  class { 'portauthority::services':
    cluster_enabled => $portauthority::cluster_enabled,
    cluster_members => $portauthority::cluster_members,
    log_destination => $portauthority::log_destination,
    floating_ip     => $portauthority::floating_ip,
    host_ip         => $portauthority::host_ip,
  }

}
