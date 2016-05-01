require 'etcd-tools/mixins/hash'

module PortAuthority
  module Config

    extend self

    attr_reader :_cfg

    def method_missing(name, *_args, &_block)
      return @_cfg[name.to_sym] if @_cfg[name.to_sym] != nil
      fail(NoMethodError, "unknown configuration section #{name}", caller)
    end

    def load!
      @_cfg = {
        debug: false,
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
      files = ['/etc/port-authority.yaml', './etc/port-authority.yaml'].delete_if {|f| !File.exists?(f)}
      dir_files = Dir['/etc/port-authority.d/**.yaml'] + Dir['./etc/port-authority.d/**.yaml']
      files += dir_files
      return false if files.empty?
      files.each do |f|
        @_cfg = @_cfg.deep_merge(YAML.load_file(f))
      end
      true
    end

    def dump
      self._cfg
    end

    def to_yaml
      self._cfg.to_yaml.to_s
    end

  end
end
