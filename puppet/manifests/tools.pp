# == Class: portauthority::tools
#
class portauthority::tools {
  package { [ 'iputils-arping',
              'ruby1.9.1-dev' ]:
    ensure => present,
  } ->

  package { 'json':
    ensure   => '1.8.3',
    provider => 'gem'
  } ->

  package { 'etcd-tools':
    ensure   => latest,
    provider => 'gem',
  } ->

  package { 'port-authority-prz':
    ensure   => latest,
    provider => 'gem',
  }
}
