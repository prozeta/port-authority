# = Class: portauthority::services
#
class portauthority::services () {
  Docker::Run {
    service_prefix => 'pa-'
  }

  $c = $portauthority::cluster_members
  $etcd_peers = inline_template('<%= @c.map { |host| host.split(".").first + "=http://" + host + ":2380" }.join(",") %>')
  $etcd_hosts_sh = inline_template('<%= @c.join(" ") %>')
  $etcd_hosts_swarm = inline_template('<%= @c.map { |host| host + ":4001" }.join(",") %>')

  each($c) |$m| {
    if ( $m == $::fqdn ) {
      $am_i_manager = true
    }
  }

  docker::run { 'logger':
    image    => 'prozeta/pa-logger',
    env      => [ "LOG_DESTINATION=${portauthority::log_destination}" ],
    ports    => [ '8888:80' ],
    use_name => true,
    volumes  => [ '/var/run/docker.sock:/tmp/docker.sock' ],
  }

  if $portauthority::cluster_enabled {

    if defined($am_i_manager) {

      docker::run { 'etcd':
        image    => 'prozeta/pa-etcd',
        env      => [ 'CLUSTER_ENABLED=true', "ETCD_HOSTNAME=${::hostname}" , "HOST_IP=${portauthority::host_ip}", "PEERS='${etcd_peers}'", "ETCD_HOSTS='${etcd_hosts_sh}'" ],
        use_name => true,
        net      => 'host',
        volumes  => [ '/var/lib/etcd:/var/lib/etcd' ],
        depends  => [ 'pa-logger' ],
      }

      docker::run { 'manager':
        image    => 'swarm',
        command  => "manage --replication --replication-ttl '10s' --addr ${portauthority::host_ip}:2375 etcd://${etcd_hosts_swarm}/_pa",
        use_name => true,
        net      => 'host',
        depends  => [ 'pa-logger', 'pa-swarm', 'pa-etcd' ],
      }

    }

    docker::run { 'registrator':
      image    => 'prozeta/pa-registrator',
      env      => [ "ETCD_HOST=${portauthority::floating_ip}", "PUBLISH_IP=${portauthority::host_ip}" ],
      use_name => true,
      volumes  => [ '/var/run/docker.sock:/tmp/docker.sock' ],
      depends  => [ 'pa-logger', 'pa-etcd' ],
    }

    docker::run { 'swarm':
      image    => 'swarm',
      command  => "join --addr ${portauthority::host_ip}:4243 --heartbeat '2s' --ttl '10s' etcd://${etcd_hosts_swarm}/_pa",
      use_name => true,
      net      => 'host',
      depends  => [ 'pa-logger', 'pa-etcd' ],
    }

  } else {

    docker::run { 'etcd':
      image    => 'prozeta/pa-etcd',
      env      => [ 'CLUSTER_ENABLED=false', 'ETCD_HOSTNAME=etcd' , "HOST_IP=${portauthority::host_ip}" ],
      use_name => true,
      net      => 'host',
      volumes  => [ '/var/lib/etcd:/var/lib/etcd' ],
      require  => Docker::Run['pa-logger'],
      depends  => [ 'pa-logger' ],
    } ->

    docker::run { 'registrator':
      image    => 'prozeta/pa-registrator',
      env      => [ "ETCD_HOST=${portauthority::host_ip}", "PUBLISH_IP=${portauthority::host_ip}" ],
      use_name => true,
      volumes  => [ '/var/run/docker.sock:/tmp/docker.sock' ],
      require  => Docker::Run['pa-logger'],
      depends  => [ 'pa-logger', 'pa-etcd' ],

    }

  }

}
