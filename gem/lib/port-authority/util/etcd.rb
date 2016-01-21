require 'etcd'

module PortAuthority
  module Util
    module Etcd
      # connect to ETCD
      def etcd_connect!
        (host, port) = @config[:etcd][:endpoint].gsub(/^https?:\/\//, '').gsub(/\/$/, '').split(':')
        etcd = ::Etcd.client(host: host, port: port)
        begin
          versions = JSON.parse(etcd.version)
          info "conncted to ETCD at #{@config[:etcd][:endpoint]}"
          info "server version: #{versions['etcdserver']}"
          info "cluster version: #{versions['etcdcluster']}"
          info "healthy: #{etcd.healthy?}"
          return etcd
        rescue Exception => e
          err "couldn't connect to etcd at #{host}:#{port}"
          err "#{e.message}"
          @exit = true
          return nil
        end
      end

      def swarm_leader(etcd)
        etcd.get('/_pa/docker/swarm/leader').value
      end

      def am_i_leader?(etcd)
        Socket.ip_address_list.map(){|a| a.ip_address }.member?(swarm_leader(etcd).split(':').first)
      rescue Exception => e
        false
      end

    end
  end
end
