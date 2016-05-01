module PortAuthority
  module Config

    extend self

    attr_reader :_cfg

    @_cfg = default_config

    def method_missing(name, *_args, &_block)
      @_cfg[name.to_sym] || fail(NoMethodError, "unknown configuration section #{name}", caller)
    end


    def load!
      ['/etc/port-authority.yaml', './port-authority.yaml'].each do |file|
        @_cfg = _cfg.deep_merge(YAML.load_file(file)) if File.exist?(file)
      end
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
      { debug: false,
        syslog: false,
        daemonize: false,
        etcd: {
          endpoints: ['http://localhost:2379'],
          timeout: 5
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
