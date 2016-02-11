require 'etcd-tools'

module Puppet::Parser::Functions
  newfunction(:etcd_get_keys,
              type: :rvalue,
              arity: -2,
              doc: 'Returns an Array of ETCD key names from a path') do |args|
    cl = args[1].map!{ |h| { host: h['host'], port: h['port'].to_i } } || [{ host: lookupvar('fqdn'), port: 2379 }]
    timeout = args[2] || 10
    path = args[0]
    Etcd::Client.new(cluster: cl, read_timeout: timeout).get(path).children.map(&:key).map {|k| k.split('/').last}
  end
end
