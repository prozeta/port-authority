# == Class: portauthority::etcd
#
class portauthority::etcd {
  package { 'etcd':
    ensure => latest,
  }

  file { '/etc/etcd.conf':
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    require => Package['etcd'],
    content => template('portauthority/etcd.conf.erb'),
  }

  file { '/etc/default/etcd':
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    require => Package['etcd'],
    content => template('portauthority/etcd.conf.erb'),
  }

  service { 'etcd':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true
    subscribe  => [ File['/etc/etcd.conf'], File['/etc/default/etcd'] ],
  }
}
