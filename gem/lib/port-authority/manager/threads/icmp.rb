require 'net/ping'

module PortAuthority
  module Manager
    module Threads
      def thread_icmp
        Thread.new do
          debug 'starting ICMP thread...'
          icmp = Net::Ping::ICMP.new(@config[:vip][:ip])
          until @exit
            debug 'checking state by ICMP echo'
            status = vip_alive? icmp
            @semaphore[:icmp].synchronize { @status_icmp = status }
            debug "VIP is #{status ? 'alive' : 'down' } according to ICMP"
            sleep @config[:icmp][:interval]
          end
          info 'ending ICMP thread...'
        end
      end
    end
  end
end
