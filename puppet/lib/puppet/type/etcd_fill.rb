Puppet::Type.newtype(:etcd_fill) do
  @doc = "Fills PA-ETCD with values from Hiera"

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Arbitrary name'
  end

  newparam(:host) do
    desc 'ETCD host'
    defaultto 'localhost'
  end

  newparam(:port) do
    desc 'ETCD port'
    defaultto 4001
  end

  newproperty(:source) do
    desc 'Hash with data'
    def in_sync?(is)
      is.checksum == should.checksum
    end
  end

  newproperty(:path) do
    desc 'ETCD root path'
    defaultto '/config'
  end

  newproperty(:overwrite) do
    desc 'Overwrite existing data?'
    defaultto(:false)
    newvalues(:true, :false)
  end
end
