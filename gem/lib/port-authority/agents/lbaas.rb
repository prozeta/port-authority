# rubocop:disable MethodLength, CyclomaticComplexity, Metrics/BlockNesting, Metrics/LineLength, Metrics/AbcSize, Metrics/PerceivedComplexity
require 'ipaddr'
require 'socket'
require 'port-authority/agent'
require 'port-authority/mechanism/load_balancer'
require 'port-authority/mechanism/floating_ip'

module PortAuthority
  module Agents
    class LBaaS < PortAuthority::Agent

      def run
        setup daemonize: Config.daemonize, nice: -10, root: true

        Signal.trap('USR2') { @lb_update_hook = true }
        @status_swarm = false
        @status_icmp = false

        @etcd = EtcdTools::Etcd

        thr_create(:icmp, Config.icmp[:interval]) do
          Logger.debug 'checking state by ICMP echo'
          status = FloatingIP.alive?
          thr_safe { @status_icmp = status }
          Logger.debug "VIP is #{status ? 'alive' : 'down'} according to ICMP"
        end

        thr_create(:swarm, Config.etcd[:interval]) do
          begin
            Logger.debug 'checking swarm state'
            status = @etcd.am_i_swarm_leader?
            thr_safe { @status_swarm = status }
            Logger.debug "i am #{status ? '' : 'NOT' } the swarm leader"
          rescue PortAuthority::Errors::ETCDConnectFailed => e
            Logger.error [ e.class e.message ].join(': ')
            Logger.error "  connection: " + e.etcd.to_s
            Logger.error "  #{e.backtrace.to_s}"
            thr_safe { @status_swarm = false }
            sleep Config.etcd[:interval]
            retry unless exit?
          end
        end

        thr_start

        LoadBalancer.docker_setup! || end!
        LoadBalancer.create!

        Logger.debug 'waiting for threads to gather something...'
        sleep Config.vip[:interval]
        first_cycle = true
        status_time = Time.now.to_i - 60

        until exit?
          status_swarm = status_icmp = false if first_cycle
          if @lb_update_hook
            Logger.notice 'LoadBalancer image update triggerred'
            LoadBalancer.update!
            Logger.notice 'LoadBalancer image update finished'
          end
          sleep Config.vip[:interval]
          thr_safe(:icmp) { status_icmp = @status_icmp }
          thr_safe(:swarm) { status_swarm = @status_swarm }
          if status_swarm
            Logger.debug 'i am the leader'
            if FloatingIP.up?
              Logger.debug 'got VIP, that is OK'
            else
              Logger.info 'no VIP here, checking whether it is free'
              FloatingIP.arp_del!
              if FloatingIP.reachable?
                Logger.info 'VIP is still up! (ICMP)'
              else
                Logger.info 'VIP is unreachable by ICMP, checking for duplicates on L2'
                FloatingIP.arp_del!
                if FloatingIP.duplicate?
                  Logger.error 'VIP is still assigned! (ARP)'
                else
                  Logger.notice 'VIP is free :) assigning'
                  FloatingIP.handle! status_swarm
                  Logger.notice 'updating other hosts about change'
                  FloatingIP.update_arp!
                end
              end
            end
            if LoadBalancer.up?
              Logger.debug 'load-balancer is up, that is OK'
            else
              Logger.notice 'load-balancer is down, starting'
              LoadBalancer.start!
            end
          else
            Logger.debug 'i am not the leader'
            if FloatingIP.up?
              Logger.notice 'i got VIP and should not, removing'
              FloatingIP.handle! status_swarm
              Logger.notice 'updating other hosts about change'
              FloatingIP.update_arp!
            else
              Logger.debug 'no VIP here, that is OK'
            end
            if LoadBalancer.up?
              Logger.notice 'load-balancer is up, stopping'
              LoadBalancer.stop!
            else
              Logger.debug 'load-balancer is down, that is OK'
            end
          end
        end

        thr_wait

        # remove VIP on shutdown
        if FloatingIP.up?
          Logger.notice 'removing VIP'
          FloatingIP.handle! false
          FloatingIP.update_arp!
        end

        # stop LB on shutdown
        if LoadBalancer.up?
          Logger.notice 'stopping load-balancer'
          LoadBalancer.stop!
        end

        info 'exiting...'
        exit 0
      end

      def my_ip
        @my_ip ||= Socket.ip_address_list.detect(&:ipv4_private?).ip_address
      end

    end
  end
end
