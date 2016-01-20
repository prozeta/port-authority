require 'puppet/provider/etcd'

Puppet::Type.type(:etcd_fill).provide(:etcd, parent: Puppet::Provider::Etcd) do
  confine :feature => :etcd

  attr_accessor :etcd

  mk_resource_methods

  def self.prefetch(resources)
    resources.each do |name, resource|
      Puppet.debug "prefetching for #{name}"
      etcd = etcd_init(resource[:host], resource[:port])
      resource.provider = new(, )
    end
  end

  def flush

  end

end
