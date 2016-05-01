require 'yaml'
require 'etcd-tools'

module PortAuthority
  module Config

    extend self

    @_cfg = default_config

    attr_reader :_cfg

    def method_missing(name, *_args, &_block)
      @_cfg[name.to_sym] || fail(NoMethodError, "unknown configuration root #{name}", caller)
    end


    def load!
      if File.exist? '/etc/port-authority.yaml'
        @_cfg = @_cfg.deep_merge YAML.load_file('/etc/port-authority.yaml')
      elsif File.exist? './port-authority.yaml'
        @_cfg = @_cfg.deep_merge YAML.load_file('./port-authority.yaml')
      else
        puts 'no config file loaded!'
        return false
      end
      true
    end

    def dump
      @_cfg
    end

    def to_yaml
      @_cfg.to_yaml.to_s
    end

    private
    def default_config
      { debug: true,
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
          ip: '',
          mask: '',
          interface: 'eth0'
        },
        lb: {
          image: '',
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
