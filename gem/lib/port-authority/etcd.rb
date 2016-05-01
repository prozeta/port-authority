require 'etcd'
require 'etcd-tools/mixins'

module PortAuthority
  class Etcd < EtcdTools::Etcd
    def swarm_leader
      self.get('/_pa/docker/swarm/leader').value
    end

    def am_i_swarm_leader?
      Socket.ip_address_list.map(&:ip_address).member?(swarm_leader(self).split(':').first)
    end

    def swarm_overlay_id(name)
      self.get_hash('/_pa/docker/network/v1.0/network').each_value do |network|
        return network['id'] if network['name'] == name
      end
    end

    def swarm_list_services(network, service_name='.*')
      self.get_hash("/_pa/docker/network/v1.0/endpoint/#{overlay_id(etcd, network)}").each_value do |container|
        next unless Regexp.new(service_name).match container['name']
        services =  { container['name'] => {
                        'id' => container['id'],
                        'ip' => container['ep_iface']['addr'].sub(/\/[0-9]+$/, ''),
                        'ports' => container['exposed_ports'].map { |port| port['Port'] }
                      }
                    }
      end
      services
    end
  end
end
