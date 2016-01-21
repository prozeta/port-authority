require 'docker-api'

module PortAuthority
  module Util
    module LoadBalancer
      # connect to ETCD
      def lb_docker_setup!
        Docker.url = @config[:lb][:docker_endpoint]
        Docker.version
        true
      rescue
        false
      end

      def lb_create
        @lb_container = Docker::Container.create(
          'Image' => @config[:lb][:image],
          'Name' => @config[:lb][:name],
          'Hostname' => @config[:lb][:name],
          'Net' => @config[:lb][:network]
        )
      end

      def lb_up?
        @lb_container.status
      end

      def lb_start!
        @lb_container.start # FIXME must expose ports
      end

      def lb_stop!
        @lb_container.stop
      end

    end
  end
end
