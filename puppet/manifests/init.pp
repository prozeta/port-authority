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
  $floating_ip,
  $floating_ip_mask = '255.255.255.0',
  $floating_ip_iface = 'eth0',
  $cluster_members = [],
  $private_registry = '',
  $log_destination = '',
  $host_fqdn = $::fqdn,
  $lb_image = 'prozeta/pa-haproxy:latest',
  $lb_name = 'pa-loadbalancer',
  $lb_network = 'portauthority',
  $lb_log_destination = '',
  $lb_env = 'VENDOR=portauthority',
  $cron_image = 'prozeta/pa-cron:latest',
  $cron_name = 'pa-loadbalancer',
  $cron_network = 'portauthority',
  $cron_log_destination = '',
  $cron_env = 'VENDOR=portauthority',
  $docker_listen_ip = '',
  $default_bridge_ip = '192.168.255.1/24',
  $gwbridge_network = '192.168.254.0/24',
  $gwbridge_address = '192.168.254.1',
  $dns = ['8.8.8.8', '4.4.4.4'],
  $swarm_tag = 'latest',
  $debug = false,
) {

  if $debug {
    $debug_param = '-D'
  } else {
    $debug_param = ''
  }

  # detect whether cluster is enabled
  if $cluster_members == [] {
    $cluster_enabled = false
  } else {
    $cluster_enabled = true
  }

  # detect whether i'm one of cluster managers
  $filtered_members = $cluster_members.filter |$m| { $m == $::fqdn }
  if $filtered_members == [ $::fqdn ] {
    $cluster_manager = true
  } else {
    $cluster_manager = false
  }

  # do we have a private registry?
  if $portauthority::private_registry != '' {
    $registry_cfg = "--insecure-registry ${private_registry} "
  } else {
    $registry_cfg = ''
  }

  # docker listen IP detection
  if empty($portauthority::docker_listen_ip) {
    if    ! empty($::ipaddress_eth0) { $final_docker_listen_ip = $::ipaddress_eth0 }
    elsif ! empty($::ipaddress)      { $final_docker_listen_ip = $::ipaddress }
  } else {
    $final_docker_listen_ip = $portauthority::docker_listen_ip
  }

  if $cluster_enabled == true {
    $docker_cluster_store = inline_template('<%= "etcd://" + @cluster_members.map { |host| host + ":2379" }.join(",") + "/_pa" %>')
    $final_extra_parameters = "${debug_param} ${registry_cfg} --bip ${portauthority::default_bridge_ip} --cluster-store=${docker_cluster_store} --cluster-advertise=${final_docker_listen_ip}:4243 --userland-proxy=false"
  } else {
    $final_extra_parameters = "${debug_param} ${registry_cfg} --bip ${portauthority::default_bridge_ip} --userland-proxy=false"
  }

  if $cluster_manager == true {
    class { 'portauthority::etcd':
      before => Class['docker'],
    }
  }

  class { 'docker':
    dns              => $portauthority::dns,
    extra_parameters => $final_extra_parameters,
    tcp_bind         => "tcp://${final_docker_listen_ip}:4243",
  } ->

  class { 'portauthority::tools': } ->
  class { 'portauthority::images': } ->
  class { 'portauthority::agents': } ->
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
  $extra_parameters = '',
) {

  if $portauthority::cluster_manager == true {
    $cluster_host_id = inline_template('<%= @hostname.match(/[0-9]+$/).to_s %>')
    $container_hostname = "${title}${cluster_host_id}"
    $container_title = "${title}${cluster_host_id}"
    $depends_final = $depends
  } else {
    $container_hostname = $::hostname
    $container_title = $title
    $depends_final = $depends
  }

  $env_final = [ "ETCDCTL_ENDPOINT=${endpoint}", "DOCKER_HOST=${::ipaddress_eth0}" ] + $env
  $extra_parameters_final = "--name=${container_hostname} ${extra_parameters}"

  if $directory {
    $volumes_final = [ "/srv/${title}:${directory}" ] + $volumes

    file { "/srv/${title}":
      ensure => directory,
      mode   => '0644',
      before => Docker::Run[$container_title],
    }

  } else {
    $volumes_final = $volumes
  }

  docker::run { $container_title:
    image            => $image,
    env              => $env_final,
    hostname         => $container_hostname,
    ports            => $ports,
    net              => $net,
    volumes          => $volumes_final,
    depends          => $depends_final,
    privileged       => $privileged,
    extra_parameters => $extra_parameters_final,
    service_prefix   => $service_prefix,
    pull_on_start    => false,
  }
}

# == Define: pa_network
#
define pa_network (
  $address = '192.168.64.0/22',
) {
  docker_network { $title:
    driver => 'overlay',
    subnet => $address,
  }
}
