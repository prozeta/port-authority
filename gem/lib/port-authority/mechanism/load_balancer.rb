require 'docker-api'

module PortAuthority
  module Mechanism
    module LoadBalancer

      extend self

      attr_reader :_container, :_container_def, :image

      Docker.url = Config.lb[:docker_endpoint]

      def get
        @_container ||= Docker::Container.get(Config.lb[:name])
      end

      def create
        @_image = Docker::Image.create('fromImage' => Config.lb[:image])
        port_bindings = Hash.new
        @_image.json['ContainerConfig']['ExposedPorts'].keys.each do |port|
          port_bindings[port] = [ { 'HostPort' => "#{port.split('/').first}" } ]
        end
        @_container_def = {
          'Image' => @_image.json['Id'],
          'name' => Config.lb[:name],
          'Hostname' => Config.lb[:name],
          'Env' => [ "ETCDCTL_ENDPOINT=#{Config.etcd[:endpoints].map { |e| "http://#{e}" }.join(',')}" ],
          'RestartPolicy' => { 'Name' => 'never' },
          'HostConfig' => {
            'PortBindings' => port_bindings,
            'NetworkMode' => Config.lb[:network]
          }
        }
        if Config.lb[:log_dest] != ''
          cont_def['HostConfig']['LogConfig'] = {
            'Type' => 'gelf',
            'Config' => {
              'gelf-address' => Config.lb[:log_dest],
              'tag' =>  Socket.gethostbyname(Socket.gethostname).first + '/{{.Name}}/{{.ID}}'
            }
          }
        end
        @_container = Docker::Container.create(@_container_def)
      end


      def update!
        lb_stop! if lb_up?
        lb_remove!
        lb_create!
      end

      def remove!
        @_container.delete
      end

      def up?
        @_container.json['State']['Running']
      end

      def start!
        @_container.start
      end

      def stop!
        @_container.stop
      end

    end
  end
end
