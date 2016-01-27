require 'etcd-tools'

module Puppet
  module Parser
    module Functions
      newfunction(:etcd_get, :type => :rvalue) do |args|
        hosts = args[1] || [{ host: lookupvar('fqdn'), port: 2379 }]
        timeout = args[2] || 5
        ::Etcd::Client.new(cluster: hosts, read_timeout: timeout).get(args[0]).value
      end
    end
  end
end