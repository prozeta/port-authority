require 'docker-api'

module PortAuthority
  module Mechanism
    module LoadBalancer

      extend self

      attr_reader :_container, :_container_def, :_image

      def init!
        Docker.url = Config.lbaas[:docker_endpoint]
        Docker.options = { connect_timeout: Config.lbaas[:docker_timeout] || 10 }
        self.container || ( self.pull! && self.create! )
      end

      def container
        @_container ||= Docker::Container.get(Config.lbaas[:name]) rescue nil
      end

      def image
        @_image ||= Docker::Image.create('fromImage' => Config.lbaas[:image])
      end

      def pull!
        @_image = Docker::Image.create('fromImage' => Config.lbaas[:image])
      end

      def create!
        port_bindings = Hash.new
        self.image.json['ContainerConfig']['ExposedPorts'].keys.each do |port|
          port_bindings[port] = [ { 'HostPort' => "#{port.split('/').first}" } ]
        end
        @_container_def = {
          'Image' => self.image.json['Id'],
          'name' => Config.lbaas[:name],
          'Hostname' => Config.lbaas[:name],
          'Env' => [ "ETCDCTL_ENDPOINT=#{Config.etcd[:endpoints].map { |e| "http://#{e}" }.join(',')}" ],
          'RestartPolicy' => { 'Name' => 'never' },
          'HostConfig' => {
            'PortBindings' => port_bindings,
            'NetworkMode' => Config.lbaas[:network]
          }
        }
        if Config.lbaas[:log_dest] != ''
          @_container_def['HostConfig']['LogConfig'] = {
            'Type' => 'gelf',
            'Config' => {
              'gelf-address' => Config.lbaas[:log_dest],
              'tag' =>  Socket.gethostbyname(Socket.gethostname).first + '/{{.Name}}/{{.ID}}'
            }
          }
        end
        @_container = Docker::Container.create(@_container_def)
      end


      def update!
        begin
          ( self.stop! && start = true ) if self.up?
          self.remove!
          self.pull!
          self.create!
          self.start! if start == true
        rescue StandardError => e
          Logger.error "UNCAUGHT EXCEPTION IN THREAD #{Thread.current[:name]}"
          Logger.error [' ', e.class, e.message].join(' ')
          Logger.error '  ' + e.backtrace.to_s
        end
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
