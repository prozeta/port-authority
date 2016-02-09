require 'etcd-tools'

module Puppet::Parser::Functions
  newfunction(:etcd_get_keys,
              type: :rvalue,
              arity: -2,
              doc: 'Returns an Array of ETCD key names from a path') do |args|
    hosts = args[1] || [{ host: lookupvar('fqdn'), port: 2379 }]
    timeout = args[2] || 5
    ::Etcd::Client.new(cluster: hosts, read_timeout: timeout).get(args[0]).children.map(&:key).map {|k| k.split('/').last}
  end
end
