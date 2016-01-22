# = Class: portauthority::services
#
class portauthority::services () {
  $etcd_hosts_swarm = inline_template('<%= scope["portauthority::cluster_members"].map { |host| host + ":4001" }.join(",") %>')

  Docker::Run {
    service_prefix => 'pa-'
  }

  docker::run { 'logger':
    image    => 'prozeta/pa-logger',
    env      => [ "LOG_DESTINATION=${portauthority::log_destination}" ],
    ports    => [ '8888:80' ],
    use_name => true,
    volumes  => [ '/var/run/docker.sock:/tmp/docker.sock' ],
  }

  if $portauthority::cluster_enabled {
    if $portauthority::cluster_manager {
      docker::run { 'swarm-manager':
        image    => 'swarm',
        command  => "manage --replication --replication-ttl '10s' --addr ${portauthority::host_ip}:2375 etcd://${etcd_hosts_swarm}/_pa",
        use_name => true,
        net      => 'host',
        depends  => [ 'logger', 'swarm-agent' ],
      } # ->
      # service { 'pa-manager':
      #   ensure     => running,
      #   enable     => true,
      #   hasrestart => true,
      #   hasstatus  => true,
      # }
    } else {
      # service { 'pa-manager':
      #   ensure => stopped,
      #   enable => false,
      # }
    }
    docker::run { 'registrator':
      image    => 'prozeta/pa-registrator',
      env      => [ "ETCD_HOST=${portauthority::floating_ip}", "PUBLISH_IP=${portauthority::host_ip}" ],
      use_name => true,
      volumes  => [ '/var/run/docker.sock:/tmp/docker.sock' ],
      depends  => [ 'logger' ],
    }
    docker::run { 'swarm-agent':
      image    => 'swarm',
      command  => "join --addr ${portauthority::host_ip}:4243 --heartbeat '2s' --ttl '10s' etcd://${etcd_hosts_swarm}/_pa",
      use_name => true,
      net      => 'host',
      depends  => [ 'logger' ],
    }
  } else {
    docker::run { 'registrator':
      image    => 'prozeta/pa-registrator',
      env      => [ "ETCD_HOST=${portauthority::host_ip}", "PUBLISH_IP=${portauthority::host_ip}" ],
      use_name => true,
      volumes  => [ '/var/run/docker.sock:/tmp/docker.sock' ],
      require  => Docker::Run['logger'],
      depends  => [ 'logger' ],
    }
  }
}
