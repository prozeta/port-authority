require 'docker-api'

module PortAuthority
  module Manager
    class LB

      attr_reader :container, :container_def, :config, :image

      def initialize config
        @config = config
        Docker.url = @config[:lb][:docker_endpoint]
      end

      def get
        @container ||= Docker::Container.get(@config[:lb][:name])
      end

      def create_container
        @image = Docker::Image.create('fromImage' => @config[:lb][:image])
        port_bindings = Hash.new
        @image.json['ContainerConfig']['ExposedPorts'].keys.each do |port|
          port_bindings[port] = [ { 'HostPort' => "#{port.split('/').first}" } ]
        end
        @container_def = {
          'Image' => @image.json['Id'],
          'name' => @config[:lb][:name],
          'Hostname' => @config[:lb][:name],
          'Env' => [ "ETCDCTL_ENDPOINT=#{@config[:etcd][:endpoints].map { |e| "http://#{e}" }.join(',')}" ],
          'RestartPolicy' => { 'Name' => 'never' },
          'HostConfig' => {
            'PortBindings' => port_bindings,
            'NetworkMode' => @config[:lb][:network]
          }
        }
        if @config[:lb][:log_dest] != ''
          cont_def['HostConfig']['LogConfig'] = {
            'Type' => 'gelf',
            'Config' => {
              'gelf-address' => @config[:lb][:log_dest],
              'tag' =>  Socket.gethostbyname(Socket.gethostname).first + '/{{.Name}}/{{.ID}}'
            }
          }
        end
        @container = Docker::Container.create(@container_def)
      end


      def lb_update
        lb_stop! if lb_up?
        lb_remove!
        lb_create!
        @lb_update_hook = false
      end

      def lb_remove!
        @container.delete
      end

      def lb_up?
        @container.json['State']['Running']
      end

      def lb_start!
        @container.start
      end

      def lb_stop!
        @container.stop
      end

    end
  end
end
