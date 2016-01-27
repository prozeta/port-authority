require 'puppet/provider/etcd'

Puppet::Type.type(:etcd_set_hash).provide :ruby do
  confine :feature => :etcd_tools

  mk_resource_methods

  def self.instances
  end

  def self.prefetch(resources)
    resources.each do |name, resource|
      Puppet.debug "prefetching for #{name}"
      etcd = etcd_init(resource[:host], resource[:port])
      resource.provider = new(, )
    end
  end

end
