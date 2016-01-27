require 'digest/sha2'
require 'etcd-tools'


class Puppet::Error::EtcdConnectionError < Puppet::Error
end


class Puppet::Provider::Etcd < Puppet::Provider

  private

  def etcd_connect!
    e = ::Etcd::Client.new(
      host: @resource.value(:host),
      port: @resource.value(:port)
    )
    e.version
    e
  rescue
    raise Puppet::Error::EtcdConnectionError, 'Failed to connect to ETCD'
  end

end
