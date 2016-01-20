require 'etcd'

module PortAuthority
  module Util
    module Swarm
      # connect to ETCD
      def etcd_connect!
        (host, port) = @config[:etcd][:endpoint].gsub(/^https?:\/\//, '').gsub(/\/$/, '').split(':')
        etcd = ::Etcd.client(host: host, port: port)
        begin
          versions = JSON.parse(etcd.version)
          info "<swarm> conncted to ETCD at #{@config[:etcd][:endpoint]}"
          info "<swarm> server version: #{versions['etcdserver']}"
          info "<swarm> cluster version: #{versions['etcdcluster']}"
          info "<swarm> healthy: #{etcd.healthy?}"
          return etcd
        rescue Exception => e
          err "<swarm> couldn't connect to etcd at #{host}:#{port}"
          err "<swarm> #{e.message}"
          @exit = true
          return nil
        end
      end

      def get_leader(etcd)
        etcd.get('/_pa/docker/swarm/leader')
      end

      def leader?(etcd)
        swarm_leader = etcd.get('/_pa/docker/swarm/leader').split(':').first
        addresses = Socket.ip_address_list.map(){|a| a.ip_address }
        return addresses.member? swarm_leader
      rescue Exception => e
        return false
      end

    end
  end
end
