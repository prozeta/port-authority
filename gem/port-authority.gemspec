Gem::Specification.new do |s|
  s.name                  = 'port-authority'
  s.version               = '0.5.2'
  s.date                  = Time.now.strftime('%Y-%m-%d')
  s.summary               = 'Port Authority'
  s.description           = 'Highly opinionated PaaS based on Docker Swarm and ETCD'
  s.authors               = ["Radek 'blufor' Slavicinsky", "Tomas 'arteal' Hejatko", "Jan 'liquid' Kaufman"]
  s.email                 = 'cloud@prozeta.eu'
  s.files                 = Dir['lib/**/*.rb']
  s.executables           = Dir['bin/*'].map { |f| f.split('/').last }
  s.homepage              = 'https://github.com/prozeta/port-authority'
  s.license               = 'GPLv2'
  s.required_ruby_version = '>= 1.9.3'
  s.add_runtime_dependency 'etcd', '~> 0.3', '>= 0.3.0'
  s.add_runtime_dependency 'etcd-tools', '~> 0.4', '>= 0.4.4'
  s.add_runtime_dependency 'net-ping', '~> 1.7', '>= 1.7.8'
  s.add_runtime_dependency 'docker-api', '~> 1.0', '>= 1.25.0'
end
