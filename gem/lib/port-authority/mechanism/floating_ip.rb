# rubocop:disable Metrics/LineLength, Metrics/AbcSize
module PortAuthority
  module Mechanism
    module FloatingIP

      extend self

      attr_accessor :_icmp

      @_icmp = Net::Ping::ICMP.new(Config.vip[:ip])

      # add or remove VIP on interface
      def handle!(leader)
        ip = IPAddr.new(Config.vip[:ip])
        mask = Config.vip[:mask]
        cmd = [Config.commands[:iproute], 'address', '', "#{ip}/#{mask}", 'dev', Config.vip[:interface], '>/dev/null 2>&1']
        leader ? cmd[2] = 'add' : cmd[2] = 'delete'
        return true if shellcmd cmd
        false
      end

      # send gratuitous ARP to the network
      def arp_update!
        return true if shellcmd [Config.commands[:arping], '-U', '-q', '-c', Config.arping[:count], '-I', Config.vip[:interface], Config.vip[:ip]]
        false
      end

      # check whether VIP is assigned to me
      def up?
        Socket.ip_address_list.map(&:ip_address).member?(Config.vip[:ip])
      end

      # check reachability of VIP by ICMP echo
      def alive?
        (1..Config.icmp[:count]).each { return true if @_icmp.ping }
        false
      end

      def arp_del!
        return true if shellcmd [Config.commands[:arp], '-d', Config.vip[:ip], '>/dev/null 2>&1']
        false
      end

      # check whether the IP is registered anywhere
      def duplicate?
        return true if shellcmd [Config.commands[:arping], '-D', '-q', '-c', Config.arping[:count], '-w', Config.arping[:wait], '-I', Config.vip[:interface], Config.vip[:ip]]
        false
      end
    end
  end
end
