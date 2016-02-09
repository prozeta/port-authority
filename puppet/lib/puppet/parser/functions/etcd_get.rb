require 'etcd-tools'

module Puppet::Parser::Functions
  newfunction(:etcd_get,
              type: :rvalue,
              arity: -2,
              doc: 'Get a value of an ETCD key') do |args|
    hosts = args[1] || [{ host: lookupvar('fqdn'), port: 2379 }]
    timeout = args[2] || 5
    ::Etcd::Client.new(cluster: hosts, read_timeout: timeout).get(args[0]).value
  end
end
