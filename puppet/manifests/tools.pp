# == Class: portauthority::tools
#
class portauthority::tools {
  package { [ 'iputils-arping',
              'ruby1.9.1-dev' ]:
    ensure => present,
  } ->

  package { 'etcd-tools':
    ensure   => latest,
    provider => 'gem',
  } ->

  package { 'port-authority':
    ensure   => latest,
    provider => 'gem',
  }
}
