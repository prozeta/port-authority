module PortAuthority
  module Manager
  end

  module Services
  end

  module Util
  end

  module Errors

    class ETCDConnectFailed < StandardError
      attr_reader :etcd, :message
      def initialize(etcd, message = "Can't connect to ETCD")
        @message = message
        @etcd = etcd
      end
    end

    class ETCDIsSick < StandardError
      attr_reader :etcd, :message
      def initialize(etcd, message = 'ETCD is not healthy')
        @message = message
        @etcd = etcd
      end
    end

  end

end
