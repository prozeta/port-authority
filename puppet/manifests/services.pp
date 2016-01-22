# = Class: portauthority::services
#
class portauthority::services () {
  $etcd_hosts_sh = inline_template('<%= scope["portauthority::cluster_members"].join(" ") %>')
  $etcd_hosts_swarm = inline_template('<%= scope["portauthority::cluster_members"].map { |host| host + ":4001" }.join(",") %>')
  $am_i_manager = false
  each($portauthority::cluster_members) |$m| { if ( $m == $::fqdn ) { $am_i_manager = true } }

  Docker::Run {
    service_prefix => 'pa-'
  } ->

  docker::run { 'logger':
    image    => 'prozeta/pa-logger',
    env      => [ "LOG_DESTINATION=${portauthority::log_destination}" ],
    ports    => [ '8888:80' ],
    use_name => true,
    volumes  => [ '/var/run/docker.sock:/tmp/docker.sock' ],
  }

  if $portauthority::cluster_enabled {
    if $am_i_manager {
      docker::run { 'etcd':
        image    => 'prozeta/pa-etcd',
        env      => [ 'CLUSTER_ENABLED=true', "ETCD_HOSTNAME=${::hostname}" , "HOST_IP=${portauthority::host_ip}", "PEERS='${etcd_peers}'", "ETCD_HOSTS='${etcd_hosts_sh}'" ],
        use_name => true,
        net      => 'host',
        volumes  => [ '/var/lib/etcd:/var/lib/etcd' ],
        depends  => [ 'logger' ],
      }
      docker::run { 'swarm-manager':
        image    => 'swarm',
        command  => "manage --replication --replication-ttl '10s' --addr ${portauthority::host_ip}:2375 etcd://${etcd_hosts_swarm}/_pa",
        use_name => true,
        net      => 'host',
        depends  => [ 'logger', 'swarm-agent', 'etcd' ],
      } ->
      service { 'pa-manager':
        ensure     => running,
        enable     => true,
        hasrestart => true,
        hasstatus  => true,
      }
    } else {
      service { 'pa-manager':
        ensure => stopped,
        enable => false,
      }
    }
    docker::run { 'registrator':
      image    => 'prozeta/pa-registrator',
      env      => [ "ETCD_HOST=${portauthority::floating_ip}", "PUBLISH_IP=${portauthority::host_ip}" ],
      use_name => true,
      volumes  => [ '/var/run/docker.sock:/tmp/docker.sock' ],
      depends  => [ 'logger', 'etcd' ],
    }
    docker::run { 'swarm-agent':
      image    => 'swarm',
      command  => "join --addr ${portauthority::host_ip}:4243 --heartbeat '2s' --ttl '10s' etcd://${etcd_hosts_swarm}/_pa",
      use_name => true,
      net      => 'host',
      depends  => [ 'logger', 'etcd' ],
    }
  } else {
    docker::run { 'etcd':
      image    => 'prozeta/pa-etcd',
      env      => [ 'CLUSTER_ENABLED=false', 'ETCD_HOSTNAME=etcd' , "HOST_IP=${portauthority::host_ip}" ],
      use_name => true,
      net      => 'host',
      volumes  => [ '/var/lib/etcd:/var/lib/etcd' ],
      require  => Docker::Run['logger'],
      depends  => [ 'logger' ],
    }
    docker::run { 'registrator':
      image    => 'prozeta/pa-registrator',
      env      => [ "ETCD_HOST=${portauthority::host_ip}", "PUBLISH_IP=${portauthority::host_ip}" ],
      use_name => true,
      volumes  => [ '/var/run/docker.sock:/tmp/docker.sock' ],
      require  => Docker::Run['logger'],
      depends  => [ 'logger', 'etcd' ],
    }
  }
}
