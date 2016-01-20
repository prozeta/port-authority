require 'yaml'
require 'json'
require 'digest/sha2'
require 'etcd-tools/etcd'


class Puppet::Error::EtcdConnectionError < Puppet::Error
end


class Puppet::Provider::Etcd < Puppet::Provider

  initvars

  ## functions needed by ensure

  def create
    @property_hash[:ensure] = :present
    self.class.resource_type.validproperties.each do |property|
      if val = resource.should(property)
        @property_hash[property] = val
      end
    end
  end

  def destroy
    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] != :absent
  end

  # helper functions

  class << self

    def etcd_init(host, port)
      begin
        etcd = Etcd.client(host: host, port: port)
        etcd.version
        return etcd
      rescue Puppet::ExecutionFailure => e
        raise Puppet::Error::EtcdConnectionError "Can't connect to ETCD"
      end
    end

    def etcd_get(etcd)
    end

    def etcd_set(etcd)
    end

    def etcd_to_hash (etcd, path)
    end

    def checksum (hash)
      Digest::SHA256.hexdigest Marshal::dump(hash)
    end

  end

end
