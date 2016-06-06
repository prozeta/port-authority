# == Class: portauthority::agents
#
class portauthority::agents {
  file { '/etc/port-authority.yaml':
    ensure  => file,
    mode    => '0644',
    owner   => 'root',
    content => template('portauthority/port-authority.yaml.erb'),
  }

  file { '/etc/port-authority.d':
    ensure  => directory,
    mode    => '0644',
    owner   => 'root',
    content => template('portauthority/port-authority.yaml.erb'),
  }


  file { '/etc/port-authority.d/lbaas.yaml':
    ensure  => file,
    mode    => '0600',
    owner   => 'root',
    content => template('portauthority/lbaas.yaml.erb'),
  }

  file { '/etc/init/pa-lbaas-agent.conf':
    ensure    => file,
    mode      => '0644',
    owner     => 'root',
    source    => 'puppet:///modules/portauthority/pa-lbaas-agent.upstart',
  }

  file { '/etc/port-authority.d/cron.yaml':
    ensure  => file,
    mode    => '0600',
    owner   => 'root',
    content => template('portauthority/cron.yaml.erb'),
  }

  file { '/etc/init/pa-lbaas-cron.conf':
    ensure    => file,
    mode      => '0644',
    owner     => 'root',
    source    => 'puppet:///modules/portauthority/pa-cron-agent.upstart',
  }

}
