require 'puppet/provider/etcd'

Puppet::Type.type(:etcd_set).provide(:etcd, parent: Puppet::Provider::Etcd) do
  confine :feature => :etcd

  mk_resource_methods

  def initialize(var, *args)
  end

end
