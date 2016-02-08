# = Class: portauthority::images
#
class portauthority::images () {

  docker::image { 'swarm':
    ensure    => present,
    image_tag => $portauthority::swarm_tag,
  }

}
