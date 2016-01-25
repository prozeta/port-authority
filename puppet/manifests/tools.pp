# == Class: portauthority::tools
#
class portauthority::tools {
  package { 'iputils-arping':
    ensure => present,
  } ->

  package { 'etcd-tools':
    ensure   => latest,
    provider => 'gem',
  } ->

  package { 'port-authority':
    ensure   => latest,
    provider => 'gem',
  } ->

  file { '/etc/port-authority.yaml':
    ensure  => file,
    mode    => '0600',
    owner   => 'root',
    content => template('portauthority/port-authority.yaml.erb'),
  } ->

  file { '/etc/init/pa-manager.conf':
    ensure  => file,
    mode    => '0644',
    owner   => 'root',
    content => 'source:///portauthority/pa-manager.upstart',
  }
}
