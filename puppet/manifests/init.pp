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
  $default_bridge_ip = '192.168.255.1/24',
  $gwbridge_network = '192.168.254.0/24',
  $gwbridge_address = '192.168.254.1',
  $dns = ['8.8.8.8', '4.4.4.4'],
  $etcd_tag = 'latest',
  $logger_tag = 'latest',
  $registrator_tag = 'latest',
  $swarm_tag = 'latest',
) {

  if $portauthority::private_registry != '' {
    $registry_cfg = "--insecure-registry ${private_registry} "
  } else {
    $registry_cfg = ''
  }

  if $cluster_enabled {
    $docker_cluster_store = inline_template('<%= "etcd://" + @cluster_members.map { |host| host + ":4001" }.join(",") + "/_pa" %>')
    $final_extra_parameters = "${registry_cfg} --bip ${portauthority::default_bridge_ip} --cluster-store=${docker_cluster_store} --cluster-advertise=${host_ip}:4243"
  } else {
    $final_extra_parameters = "${registry_cfg} --bip ${portauthority::default_bridge_ip}"
  }

  package { 'etcd-tools':
    ensure   => latest,
    provider => 'gem',
  }

  class { 'docker':
    dns              => $portauthority::dns,
    extra_parameters => $final_extra_parameters,
    tcp_bind         => "tcp://${portauthority::host_ip}:4243",
  } ->

  class { 'portauthority::images': } ->
  class { 'portauthority::services': } ->
  class { 'portauthority::network': }

}

# == Define: pa_service
#
define pa_service (
  $image,
  $env = [],
  $ports = [],
  $directory = false,
  $volumes = [],
  $net = 'bridge',
  $depends = [],
  $memory_limit = '',
  $cpu_set = [],
  $service_prefix = 'docker-',
  $privileged = false,
  $endpoint = $::ipaddress_eth0,
) {

  $cluster_host_id = inline_template('<%= @hostname.match(/[0-9]+$/).to_s %>')
  $env_final = [ "ETCDCTL_ENDPOINT=${endpoint}", "DOCKER_HOST=${::ipaddress_eth0}" ] + $env


  if $directory {
    $volumes_final = [ "/srv/${title}:${directory}" ] + $volumes

    file { "/srv/${title}":
      ensure => directory,
      mode   => '0644',
      before => Docker::Run["${title}${cluster_host_id}"],
    }

  } else {
    $volumes_final = $volumes
  }

  docker::run { "${title}${cluster_host_id}":
    image            => $image,
    env              => $env_final,
    hostname         => "${title}${cluster_host_id}",
    ports            => $ports,
    net              => $net,
    volumes          => $volumes_final,
    depends          => $depends,
    privileged       => $privileged,
    use_name         => false,
    extra_parameters => "--name=${title}${cluster_host_id}",
    service_prefix   => $service_prefix,
    pull_on_start    => false,
  }

  # exec { "container_name_fix_${title}":
  #   command     => "/usr/bin/perl -i -ne 'print unless /--name\ ${title}.*/' /etc/init.d/${service_prefix}${title}",
  #   refreshonly => true,
  #   subscribe   => File["/etc/init.d/${service_prefix}${title}"],
  #   before      => Service["${service_prefix}${title}"],
  # }

}

# == Define: pa_network
#
define pa_network (
  $address = '192.168.64.0/22',
  $swarm_ip = $::ipaddress_eth0,
  $swarm_port = 2375,
) {

  exec { "pa_network_overlay_${title}":
    unless      => "docker network inspect ${title} >/dev/null 2>&1",
    command     => "docker network create -d overlay --subnet=${address} ${title} >/dev/null 2>&1",
    path        => '/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin:/usr/local/sbin',
    environment => [ "DOCKER_HOST=${swarm_ip}:${swarm_port}" ],
  }
}
