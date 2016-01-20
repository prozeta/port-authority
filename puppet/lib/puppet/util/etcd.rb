class Puppet::Util::Etcd
  def initialize(host, port, path)
    @etcd = Etcd.client(host: host, port: port)
    @path = path

    begin
      @etcd.members
    rescue => e
      raise Puppet::ParseError
    end
  end

  def get

  end

  def put

  end

  def to_hash (path='/')
    hash = Hash.new
    @etcd.get(path).children.each do |child|
      if @etcd.get(child.key).directory?
        hash[child.key.split('/').last.to_sym] = to_hash(child.key)
      else
        hash[child.key.split('/').last.to_sym] = child.value
      end
    end
    return hash.sort.to_h
  end

  def checksum (path='/')
    Digest::SHA256.hexdigest(Marshal::dump(self.to_hash(path)))
  end
end
