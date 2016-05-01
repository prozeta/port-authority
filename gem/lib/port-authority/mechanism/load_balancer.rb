require 'docker-api'

module PortAuthority
  module Mechanism
    module LoadBalancer

      extend self

      attr_reader :_container, :_container_def, :_image

      Docker.url = Config.lbaas[:docker_endpoint]

      def container
        @_container ||= Docker::Container.get(Config.lbaas[:lb_name])
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
          'name' => Config.lbaas[:lb_name],
          'Hostname' => Config.lbaas[:lb_name],
          'Env' => [ "ETCDCTL_ENDPOINT=#{Config.etcd[:endpoints].map { |e| "http://#{e}" }.join(',')}" ],
          'RestartPolicy' => { 'Name' => 'never' },
          'HostConfig' => {
            'PortBindings' => port_bindings,
            'NetworkMode' => Config.lbaas[:network]
          }
        }
        if Config.lbaas[:log_dest] != ''
          cont_def['HostConfig']['LogConfig'] = {
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
          self.stop! && start = true if self.lb_up?
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
        self.container.delete
      end

      def up?
        self.container.json['State']['Running']
      end

      def start!
        self.container.start
      end

      def stop!
        self.container.stop
      end

    end
  end
end
