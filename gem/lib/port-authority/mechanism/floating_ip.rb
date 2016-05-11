# rubocop:disable Metrics/LineLength, Metrics/AbcSize
require 'net/ping'
require 'digest/sha2'

module PortAuthority
  module Mechanism
    module FloatingIP

      extend self

      attr_accessor :_icmp

      def init!
        @_icmp = Net::Ping::ICMP.new(Config.lbaas[:floating_ip])
        Logger.debug(Config.lbaas.to_yaml)
      end

      # add or remove VIP on interface
      def handle!(leader)
        return true if shellcmd Config.commands[:iproute], 'address', leader ? 'add' : 'delete', "#{Config.lbaas[:floating_ip]}/32", 'dev', Config.lbaas[:floating_iface], '>/dev/null 2>&1'
        false
      end

      # send gratuitous ARP to the network
      def arp_update!
        return true if shellcmd Config.commands[:arping], '-U', '-q', '-c', Config.lbaas[:arping_count], '-I', Config.lbaas[:floating_iface], Config.lbaas[:floating_ip]

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
        return false if shellcmd Config.commands[:arping], '-D', '-q', '-c', Config.lbaas[:arping_count], '-w', Config.lbaas[:arping_wait], '-I', Config.lbaas[:floating_iface], Config.lbaas[:floating_ip]
        true
      end

      private
      def shellcmd(*args)
        cmd = args.join(' ').to_s
        cksum = Digest::SHA256.hexdigest(args.join.to_s)[0..15]
        Logger.debug "Executing shellcommand #{cksum} - #{cmd}"
        ret = system cmd
        Logger.debug "Shellcommand #{cksum} returned #{ret.to_s}"
        return ret
      end

    end
  end
end
