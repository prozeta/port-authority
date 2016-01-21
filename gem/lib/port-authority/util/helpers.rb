require 'socket'

module PortAuthority
  module Util
    module Helpers
      def hostname
        @hostname ||= Socket.gethostname
      end

      def my_ip
        @my_ip ||= Socket.ip_address_list.detect { |i| i.ipv4_private? }.ip_address
      end

      def arping
        @config[:commands][:arping]
      end

      def iproute
        @config[:commands][:iproute]
      end

      def arp
        @config[:commands][:arp]
      end
    end
  end
end
