# rubocop:disable Metrics/LineLength, Metrics/AbcSize
require 'net/ping'

module PortAuthority
  module Mechanism
    module FloatingIP

      extend self

      attr_accessor :_icmp

      @_icmp = Net::Ping::ICMP.new(Config.lbaas[:floating_ip])

      # add or remove VIP on interface
      def handle!(leader)
        return true if shellcmd Config.commands[:iproute], 'address', leader ? 'add' : 'delete', "#{Config.lbaas[:floating_ip]}/32", 'dev', Config.lbaas[:interface], '>/dev/null 2>&1'
        false
      end

      # send gratuitous ARP to the network
      def arp_update!
        return true if shellcmd Config.commands[:arping], '-U', '-q', '-c', Config.lbaas[:arping_count], '-I', Config.lbaas[:interface], Config.lbaas[:floating_ip]
        false
      end

      # check whether VIP is assigned to me
      def up?
        Socket.ip_address_list.map(&:ip_address).member?(Config.lbaas[:floating_ip])
      end

      # check reachability of VIP by ICMP echo
      def reachable?
        (1..Config.lbaas[:icmp_count]).each { return true if @_icmp.ping }
        false
      end

      def arp_del!
        return true if shellcmd Config.commands[:arp], '-d', Config.lbaas[:floating_ip], '>/dev/null 2>&1'
        false
      end

      # check whether the IP is registered anywhere
      def duplicate?
        return true if shellcmd Config.commands[:arping], '-D', '-q', '-c', Config.lbaas[:arping_count], '-w', Config.lbaas[:arping_wait], '-I', Config.lbaas[:interface], Config.lbaas[:floating_ip]
        false
      end
    end
  end
end
