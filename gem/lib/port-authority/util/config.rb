require 'yaml'
require 'etcd-tools'

module PortAuthority
  module Util
    module Config

      def config
        cfg = default_config
        if File.exist? '/etc/port-authority.yaml'
          cfg = cfg.deep_merge YAML.load_file('/etc/port-authority.yaml')
          puts 'loaded config from /etc/port-authority.yaml'
        elsif File.exist? './port-authority.yaml'
          cfg = cfg.deep_merge YAML.load_file('./port-authority.yaml')
          puts 'loaded config from ./port-authority.yaml'
        else
          puts 'no config file loaded, using defaults'
        end
        cfg
      end

      private

      def default_config
        { debug: false,
          syslog: false,
          etcd: {
            endpoints: ['http://localhost:2379'],
            interval: 5,
            timeout: 5
          },
          icmp: {
            count: 5,
            interval: 2
          },
          arping: {
            count: 1,
            wait: 1
          },
          vip: {
            interval: 1,
            ip: '172.17.1.5',
            mask: '255.255.255.0',
            interface: 'eth0'
          },
          lb: {
            image: 'docker-registry.prz/stackdocks/haproxy:latest',
            name: 'lb',
            network: 'overlay',
            docker_endpoint: 'unix:///var/run/docker.sock',
            log_dest: '',
          },
          commands: {
            arping: `which arping`.chomp,
            arp: `which arp`.chomp,
            iproute: `which ip`.chomp
          }
        }
      end
    end
  end
end
