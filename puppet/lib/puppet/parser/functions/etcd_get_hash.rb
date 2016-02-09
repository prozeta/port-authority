require 'etcd-tools'

module Puppet::Parser::Functions
  newfunction(:etcd_get_hash,
              type: :rvalue,
              arity: -2,
              doc: 'Get a Hash from ETCD path') do |args|
    hosts = args[1] || [{ host: lookupvar('fqdn'), port: 2379 }]
    timeout = args[2] || 5
    ::Etcd::Client.new(cluster: hosts, read_timeout: timeout).get_hash(args[0])
  end
end
