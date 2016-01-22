# = Class: portauthority::images
#
class portauthority::images () {

  docker::image { 'prozeta/pa-logger':
    ensure    => present,
    image_tag => $portauthority::logger_tag,
  }

  docker::image { 'prozeta/pa-registrator':
    ensure    => present,
    image_tag => $portauthority::registrator_tag,
  }

  docker::image { 'swarm':
    ensure    => present,
    image_tag => $portauthority::swarm_tag,
  }

}
