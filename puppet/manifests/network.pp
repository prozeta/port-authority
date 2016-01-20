# == Class: portauthority::network
#
class portauthority::network {
  if $portauthority::cluster_enabled {
    exec { 'pa_network_gwbridge':
      unless  => 'docker network inspect docker_gwbridge',
      command => "docker network create -d bridge -o com.docker.network.bridge.enable_icc=false -o com.docker.network.bridge.enable_ip_masquerade=true --subnet=${::portauthority::gwbridge_network} --gateway=${::portauthority::gwbridge_address} docker_gwbridge",
      path    => '/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin:/usr/local/sbin',
    }
  }
}
