# rubocop:disable Metrics/LineLength, Metrics/AbcSize
module PortAuthority
  module Util
    module Vip
      # add or remove VIP on interface
      # <IMPLEMENTED>
      def vip_handle!(leader)
        ip = IPAddr.new(@config[:vip][:ip])
        mask = @config[:vip][:mask]
        cmd = [iproute, 'address', '', "#{ip}/#{mask}", 'dev', @config[:vip][:interface], 'label', @config[:vip][:interface] + '-vip', '>/dev/null 2>&1']
        leader ? cmd[2] = 'add' : cmd[2] = 'delete'
        debug "#{cmd.join(' ')}"
        if system(cmd.join(' '))
          return true
        else
          return false
        end
      end

      # send gratuitous ARP to the network
      def vip_update_arp!
        cmd = [arping, '-U', '-q', '-c', @config[:arping][:count], '-I', @config[:vip][:interface], @config[:vip][:ip]]
        debug "#{cmd.join(' ')}"
        if system(cmd.join(' '))
          return true
        else
          return false
        end
      end

      # check whether VIP is assigned to me
      def got_vip?
        Socket.ip_address_list.map(&:ip_address).member?(@config[:vip][:ip])
      end

      # check reachability of VIP by ICMP echo
      def vip_alive?(icmp)
        (1..@config[:icmp][:count]).each { return true if icmp.ping }
        false
      end

      # check whether the IP is registered anywhere
      def vip_dup?
        cmd_arp = [arp, '-d', @config[:vip][:ip], '>/dev/null 2>&1']
        cmd_arping = [arping, '-D', '-q', '-c', @config[:arping][:count], '-w', @config[:arping][:wait], '-I', @config[:vip][:interface], @config[:vip][:ip]]
        debug "#{cmd_arp.join(' ')}"
        system(cmd_arp.join(' '))
        debug "#{cmd_arping.join(' ')}"
        if system(cmd_arping.join(' '))
          return false
        else
          return true
        end
      end
    end
  end
end
