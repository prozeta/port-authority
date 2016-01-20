require 'socket'

module PortAuthority
  module Util
    module Helpers
      def hostname
        @hostname ||= Socket.gethostname
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
