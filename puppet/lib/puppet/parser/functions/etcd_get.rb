require 'etcd-tools'

module Puppet::Parser::Functions
  newfunction(:etcd_get,
              type: :rvalue,
              arity: -2,
              doc: 'Returns a value of an ETCD key') do |args|
    cl = args[1].map!{ |h| { host: h['host'], port: h['port'].to_i } } || [{ host: lookupvar('fqdn'), port: 2379 }]
    timeout = args[2] || 10
    key = args[0]
    Etcd::Client.new(cluster: cl, read_timeout: timeout).get(args[0]).value
  end
end
