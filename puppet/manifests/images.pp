# = Class: portauthority::images
#
class portauthority::images (
  $etcd_tag,
  $logger_tag,
  $registartor_tag,
) {

  docker::image { "prozeta/pa-etcd":
    ensure => present,
    image_tag => $etcd_tag,
  }

  docker::image { "prozeta/pa-logger":
    ensure => present,
    image_tag => $logger_tag,
  }

  docker::image { "prozeta/pa-registrator":
    ensure => present,
    image_tag => $registartor_tag,
  }

}