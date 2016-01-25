require 'etcd'
require 'etcd-tools/mixins'

module PortAuthority
  module Util
    module Etcd
      # connect to ETCD
      def etcd_connect!
        endpoints = @config[:etcd][:endpoints].map { |e| e = e.gsub!(/^https?:\/\//, '').gsub(/\/$/, '').split(':'); { host: e[0], port: e[1].to_i } }
        debug "parsed ETCD endpoints: #{endpoints.to_s}"
        etcd = ::Etcd::Client.new(cluster: endpoints, read_timeout: @config[:etcd][:timeout])
        etcd if etcd.version
      rescue
        raise PortAuthority::Errors::ETCDConnectFailed.new(@config[:etcd][:endpoints])
      end

      def etcd_healthy?(etcd)
        raise PortAuthority::Errors::ETCDIsSick.new(@config[:etcd][:endpoints]) unless etcd.healthy?
      end

      def swarm_leader(etcd)
        etcd.get('/_pa/docker/swarm/leader').value
      end

      def am_i_leader?(etcd)
        Socket.ip_address_list.map(&:ip_address).member?(swarm_leader(etcd).split(':').first)
      rescue StandardError => e
        false
      end

    end
  end
end
