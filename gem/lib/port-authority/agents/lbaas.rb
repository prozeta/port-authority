# rubocop:disable MethodLength, CyclomaticComplexity, Metrics/BlockNesting, Metrics/LineLength, Metrics/AbcSize, Metrics/PerceivedComplexity
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
        @etcd = PortAuthority::Etcd.cluster_connect Config.etcd

        thr_create(:swarm, Config.lbaas[:swarm_interval] || Config.lbaas[:interval]) do
          begin
            Logger.debug 'checking swarm state'
            status = @etcd.am_i_swarm_leader?
            thr_safe { @status_swarm = status }
            Logger.debug "i am #{status ? '' : 'NOT' } the swarm leader"
          rescue StandardError => e
            Logger.error [ e.class, e.message ].join(': ')
            Logger.error "  connection: " + e.etcd.to_s
            Logger.error "  #{e.backtrace.to_s}"
            thr_safe { @status_swarm = false }
            sleep(Config.lbaas[:swarm_interval] || Config.lbaas[:interval])
            retry unless exit?
          end
        end

        thr_start

        LoadBalancer.get || LoadBalancer.create!

        Logger.debug 'waiting for threads to gather something...'
        sleep Config.lbaas[:interval]
        first_cycle = true
        status_time = Time.now.to_i - 60

        until exit?
          status_swarm = status_icmp = false if first_cycle
          if @lb_update_hook
            Logger.notice 'LoadBalancer image update triggerred'
            LoadBalancer.update!
            Logger.notice 'LoadBalancer image update finished'
          end
          sleep Config.lbaas[:interval]
          thr_safe(:icmp) { status_icmp = @status_icmp }
          thr_safe(:swarm) { status_swarm = @status_swarm }
          # main logic
          if status_swarm
            # handle FloatingIP on leader
            Logger.debug 'i am the LEADER'
            if FloatingIP.up?
              Logger.debug 'got FloatingIP, that is OK'
            else
              Logger.notice 'no FloatingIP here, checking whether it is free'
              FloatingIP.arp_del!
              if FloatingIP.reachable?
                Logger.notice 'FloatingIP is still up! (ICMP)'
              else
                Logger.info 'FloatingIP is unreachable by ICMP, checking for duplicates on L2'
                FloatingIP.arp_del!
                if FloatingIP.duplicate?
                  Logger.error 'FloatingIP is still assigned! (ARP)'
                else
                  Logger.notice 'FloatingIP is free :) assigning'
                  FloatingIP.handle! status_swarm
                  Logger.notice 'updating other hosts about change'
                  FloatingIP.update_arp!
                end
              end
            end
            # handle LoadBalancer on leader
            if LoadBalancer.up?
              Logger.debug 'LoadBalancer is up, that is OK'
            else
              Logger.notice 'LoadBalancer is down, starting'
              LoadBalancer.start!
            end
          else
            # handle FloatingIP on follower
            Logger.debug 'i am a follower'
            if FloatingIP.up?
              Logger.notice 'i got FloatingIP and should not, removing'
              FloatingIP.handle! status_swarm
              FloatingIP.arp_del!
              Logger.notice 'updating other hosts about change'
              FloatingIP.update_arp!
            else
              Logger.debug 'no FloatingIP here, that is OK'
            end
            # handle LoadBalancer on follower
            if LoadBalancer.up?
              Logger.notice 'LoadBalancer is up, stopping'
              LoadBalancer.stop!
            else
              Logger.debug 'LoadBalancer is down, that is OK'
            end
          end # logic end
        end

        thr_wait

        # remove FloatingIP on shutdown
        if FloatingIP.up?
          Logger.notice 'removing FloatingIP'
          FloatingIP.handle! false
          FloatingIP.update_arp!
        end

        # stop LB on shutdown
        if LoadBalancer.up?
          Logger.notice 'stopping LoadBalancer'
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
