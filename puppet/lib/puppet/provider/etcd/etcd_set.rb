require 'puppet/provider/etcd'

Puppet::Type.type(:etcd_set).provide :ruby do
  confine :feature => :etcd_tools

  mk_resource_methods


end
