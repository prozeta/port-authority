require File.join(File.dirname(__FILE__), '..', 'etcd')

Puppet::Type.type(:etcd_set).provide(:ruby, :parent => Puppet::Provider::Etcd) do
  confine :feature => :etcd_tools

  attr_reader :etcd

  def create
    # code
  end

  def destroy
    # code
  end

  def exists?
    # code
  end

  def value
    etcd.get(@resource.value(:path)).value
  rescue
    fail("Failed to get value of ETCD key #{@resource.value(:path)}")
  end

  def value=(should)
    etcd.set(@resource.value(:path), should.to_s)
  rescue
    fail("Failed to set value of ETCD key #{@resource.value(:path)}")
  end

  def initialize
    @etcd = etcd_connect!
  end

end
