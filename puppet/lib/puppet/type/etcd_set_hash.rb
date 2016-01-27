Puppet::Type.newtype :etcd_set_hash do
  @doc = "Fills PA-ETCD with values from provided Hash"

  ensurable do
    newvalue :synchronized do
      provider.sync = true
      provider.create
    end
    newvalue :present do
      provider.sync = false
      provider.create
    end
    newvalue :absent do
      provider.delete
    end
  end

  newparam :path do
    desc 'Base ETCD path'
    isnamevar
  end

  newproperty :hash do
    desc 'Hash with data'
    def in_sync?(is)
      is.checksum == should.checksum
    end
  end

  newparam(:host) do
    desc 'ETCD host'
    defaultto 'localhost'
  end

  newparam(:port) do
    desc 'ETCD port'
    defaultto 2379
  end

  # TLS prep
  # newparam(:tls) do
  #   desc 'SSL enabled'
  #   defaultto :false
  #   newvalues :true, :false
  # end
  #
  # newparam(:tls_ca) do
  #   desc 'Path to CA certificate file'
  # end
  #
  # newparam(:tls_cert) do
  #   desc 'Path to host certificate file'
  # end
  #
  # newparam(:tls_key) do
  #   desc 'Path to host key file'
  # end

  def initialize(args)
    super(args)
    Puppet.debug "#{self[:path]}: type initializing"
    Puppet.debug "#{self[:path]}: ensure #{self[:ensure].to_s}"
  end

  def finish
    Puppet.debug "#{self[:path]}: type finishing"
    super
  end

end
