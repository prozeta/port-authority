require 'docker-api'

module PortAuthority
  module Util
    module LoadBalancer
      # connect to Docker
      def lb_docker_setup!
        Docker.url = @config[:lb][:docker_endpoint]
        Docker.version
        true
      rescue
        false
      end

      def lb_update!
        lb_stop! if lb_up?
        lb_remove!
        lb_create!
        @lb_update_hook = false
      end

      def lb_remove!
        Docker::Container.get(@config[:lb][:name]).delete
      rescue Docker::Error::NotFoundError
      end


      def lb_create!
        lb_remove!
        img = Docker::Image.create('fromImage' => @config[:lb][:image])

        # setup port bindings hash
        port_bindings = Hash.new
        img.json['ContainerConfig']['ExposedPorts'].keys.each do |port|
          port_bindings[port] = [ { 'HostPort' => "#{port.split('/').first}" } ]
        end

        # create container with
        @lb_container = Docker::Container.create(
          'Image' => img.json['Id'],
          'name' => @config[:lb][:name],
          'Hostname' => @config[:lb][:name],
          'Env' => [ "ETCDCTL_ENDPOINT=#{@config[:etcd][:endpoints].map { |e| "http://#{e}" }.join(',')}" ],
          'RestartPolicy' => { 'Name' => 'never' },
          'HostConfig' => {
            'PortBindings' => port_bindings,
            'NetworkMode' => @config[:lb][:network]
          }
        )
      end

      def lb_up?
        @lb_container.json['State']['Running']
      end

      def lb_start!
        @lb_container.start
      end

      def lb_stop!
        @lb_container.stop
      end

    end
  end
end
