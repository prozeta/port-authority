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
      end

      def overlay_id(etcd, name)
        etcd.get_hash('/_pa/docker/network/v1.0/network').each_value do |network|
          return network['id'] if network['name'] == name
        end
      end

      def list_services(etcd, network, service_name='.*')
        svc_filter = Regexp.new(service_name)
        network_id = overlay_id(etcd, network)
        services = Hash.new
        etcd.get_hash("/_pa/docker/network/v1.0/endpoint/#{network_id}").each_value do |container|
          next unless svc_filter.match container['name']
          services[container['name']] = Hash.new
          services[container['name']]['id'] = container['id']
          services[container['name']]['ip'] = container['ep_iface']['addr'].sub(/\/[0-9]+$/, '')
          services[container['name']]['ports'] = container['exposed_ports'].map { |port| port['Port'] }
        end
        services
      end
    end
  end
end
