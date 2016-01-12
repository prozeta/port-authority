# = Class: portauthority::services
#
class portauthority::services (
  $cluster_enabled,
  $cluster_members,
  $log_destination,
  $host_ip,
  $floating_ip,
) {

  $etcd_peers = inline_template('<%= @cluster_members.map { |host| host.split(".").first + "=http://" + host + ":2380" }.join(",") %>')
  $etcd_hosts = inline_template('<%= @cluster_members.join(" ") %>')

  docker::run { 'pa-logger':
    image    => 'prozeta/pa-logger',
    env      => [ "LOG_DESTINATION=${log_destination}" ],
    ports    => [ '8888:80' ],
    use_name => true,
    volumes  => [ '/var/run/docker.sock:/tmp/docker.sock' ],
  }

  if $cluster_enabled {

    docker::run { 'pa-etcd':
      image    => 'prozeta/pa-etcd',
      env      => [ 'CLUSTER_ENABLED=true', "ETCD_HOSTNAME=${::hostname}" , "HOST_IP=${host_ip}", "PEERS='${etcd_peers}'", "ETCD_HOSTS='${etcd_hosts}'" ],
      ports    => [ '2379:2379', '2380:2380', '4001:4001', '7001:7001' ],
      use_name => true,
      hostname => "etcd-${::hostname}",
      volumes  => [ '/var/lib/etcd:/var/lib/etcd' ],
      require  => Docker::Run['pa-logger'],
    } ->

    docker::run { 'pa-registrator':
      image    => 'prozeta/pa-registrator',
      env      => [ "ETCD_HOST=${floating_ip}", "PUBLISH_IP=${host_ip}" ],
      use_name => true,
      volumes  => [ '/var/run/docker.sock:/tmp/docker.sock' ],
      require  => Docker::Run['pa-logger'],
    }

  } else {

    docker::run { 'pa-etcd':
      image    => 'prozeta/pa-etcd',
      env      => [ 'CLUSTER_ENABLED=false', 'ETCD_HOSTNAME=etcd' , "HOST_IP=${host_ip}" ],
      ports    => [ '2379:2379', '2380:2380', '4001:4001', '7001:7001' ],
      use_name => true,
      hostname => 'etcd',
      volumes  => [ '/var/lib/etcd:/var/lib/etcd' ],
      require  => Docker::Run['pa-logger'],
    } ->

    docker::run { 'pa-registrator':
      image    => 'prozeta/pa-registrator',
      env      => [ "ETCD_HOST=${host_ip}", "PUBLISH_IP=${host_ip}" ],
      use_name => true,
      volumes  => [ '/var/run/docker.sock:/tmp/docker.sock' ],
      require  => Docker::Run['pa-logger'],
    }

  }

}
