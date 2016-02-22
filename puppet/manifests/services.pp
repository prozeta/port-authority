# = Class: portauthority::services
#
class portauthority::services () {
  $etcd_hosts_swarm = inline_template('<%= scope["portauthority::cluster_members"].map { |host| host + ":2379" }.join(",") %>')

  Docker::Run {
    service_prefix => 'pa-'
  }

  if ( $portauthority::cluster_enabled == true ) {
    if ( $portauthority::cluster_manager == true ) {
      docker::run { 'swarm-manager':
        image   => 'swarm',
        command => "manage --replication --replication-ttl '10s' --addr ${portauthority::docker_listen_ip}:2375 etcd://${etcd_hosts_swarm}/_pa",
        net     => 'host',
        depends => [ 'swarm-agent' ],
      } # ->
      # service { 'pa-manager':
      #   ensure     => running,
      #   enable     => true,
      #   hasrestart => true,
      #   hasstatus  => true,
      # }
    }
    docker::run { 'swarm-agent':
      image   => 'swarm',
      command => "join --addr ${portauthority::docker_listen_ip}:4243 --heartbeat '2s' --ttl '10s' etcd://${etcd_hosts_swarm}/_pa",
      net     => 'host',
    }
  }
}
