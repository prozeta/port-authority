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

      def lb_create
        img = Docker::Image.create('fromImage' => @config[:lb][:image])

        # setup port bindings hash
        port_bindings = Hash.new
        img.json['ContainerConfig']['ExposedPorts'].keys.each do |port|
          port_bindings[port] = [ { 'HostPort' => "#{port.split('/').first}" } ]
        end

        begin
          Docker::Container.get(@config[:lb][:name]).delete
          info 'old LB removed'
        rescue Docker::Error::NotFoundError
          debug 'no LB found here, not removing'
        end

        # create container with
        @lb_container = Docker::Container.create(
          'Image' => img.json['Id'],
          'name' => @config[:lb][:name],
          'Hostname' => @config[:lb][:name],
          'Env' => [ "ETCDCTL_ENDPOINT=http://#{@config[:vip][:ip]}:4001" ],
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
