Puppet::Type.newtype(:etcd_set) do
  @doc = "Set ETCD key"

  ensurable

  newparam(:name, :namevar => true) do
    desc 'ETCD key path'
  end

  newproperty(:value) do
    desc 'ETCD key value'
  end

end
