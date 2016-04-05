# == Class: portauthority::etcd
#
class portauthority::etcd {
  package { 'etcd':
    ensure => latest,
  }

  file { '/etc/etcd.conf':
    owner   => 'etcd',
    group   => 'etcd',
    mode    => '0640',
    require => Package['etcd'],
    content => template('portauthority/etcd.conf.erb'),
  }

  file { '/etc/default/etcd':
    owner   => 'etcd',
    group   => 'etcd',
    mode    => '0640',
    require => Package['etcd'],
    content => template('portauthority/etcd.default.erb'),
  }

  file { '/etc/init/etcd.conf':
    ensure  => file,
    mode    => '0644',
    require => Package['etcd'],
    source  => 'puppet:///modules/portauthority/etcd.upstart',
  }

  file { '/etc/init.d/etcd':
    ensure => absent,
  }

  service { 'etcd':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    subscribe  => [ File['/etc/etcd.conf'], File['/etc/default/etcd'], File['/etc/init/etcd.conf'], File['/etc/init.d/etcd'] ],
  }
}
