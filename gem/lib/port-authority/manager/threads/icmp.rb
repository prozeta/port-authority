# rubocop:disable Metrics/MethodLength
require 'net/ping'

module PortAuthority
  module Manager
    module Threads
      def thread_icmp
        Thread.new do
          Thread.current[:name] = 'icmp'
          begin
            info 'starting ICMP thread...'
            icmp = Net::Ping::ICMP.new(@config[:vip][:ip])
            until @exit
              debug 'checking state by ICMP echo'
              status = vip_alive? icmp
              @semaphore[:icmp].synchronize { @status_icmp = status }
              debug "VIP is #{status ? 'alive' : 'down'} according to ICMP"
              sleep @config[:icmp][:interval]
            end
            info 'ending ICMP thread...'
          rescue StandardError => e
            alert "#{e.class}: #{e.message}"
            alert e.backtrace
            @exit = true
          end
        end
      end
    end
  end
end
