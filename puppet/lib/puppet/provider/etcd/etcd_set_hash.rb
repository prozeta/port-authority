require File.join(File.dirname(__FILE__), '..', 'etcd')

Puppet::Type.type(:etcd_set_hash).provide(:ruby, :parent => Puppet::Provider::Etcd) do
  confine :feature => :etcd_tools

  def create
    # code
  end

  def destroy
    # code
  end

  def exists?
    # code
  end

  def hash
    # code
  end

  def hash=(should)
    # code
  end


  def initialize
    @etcd = etcd_connect!
  end

end
