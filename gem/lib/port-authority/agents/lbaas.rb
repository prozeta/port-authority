# rubocop:disable MethodLength, CyclomaticComplexity, Metrics/BlockNesting, Metrics/LineLength, Metrics/AbcSize, Metrics/PerceivedComplexity
require 'socket'
require 'port-authority/agent'
require 'port-authority/mechanism/load_balancer'
require 'port-authority/mechanism/floating_ip'

module PortAuthority
  module Agents
    class LBaaS < PortAuthority::Agent
      include PortAuthority::Mechanism

      def run
        setup(daemonize: Config.daemonize, nice: -10, root: true)
        Signal.trap('HUP') { Config.load! && LoadBalancer.init! && FloatingIP.init! }
        Signal.trap('USR1') { Logger.debug! }
        Signal.trap('USR2') { @lb_update_hook = true }
        @status_swarm = false
        @etcd = PortAuthority::Etcd.cluster_connect Config.etcd

        thr_create(:swarm, Config.lbaas[:swarm_interval] || Config.lbaas[:interval]) do
          begin
            Logger.debug 'Checking Swarm state'
            status = @etcd.am_i_swarm_leader?
            thr_safe { @status_swarm = status }
            Logger.debug "I am Swarm #{status ? 'leader' : 'follower' }"
          rescue StandardError => e
            Logger.error [ e.class, e.message ].join(': ')
            e.backtrace.each {|line| Logger.debug "  #{line}"}
            thr_safe { @status_swarm = false }
            sleep(Config.lbaas[:swarm_interval] || Config.lbaas[:interval])
            retry unless exit?
          end
        end

        thr_start

        FloatingIP.init!
        LoadBalancer.init!
        LoadBalancer.container || ( LoadBalancer.pull! && LoadBalancer.create! )

        Logger.debug 'Waiting for threads to gather something...'
        sleep Config.lbaas[:interval]
        first_cycle = true
        status_time = Time.now.to_i - 60

        until exit?
          status_swarm = false if first_cycle
          if @lb_update_hook
            Logger.notice 'LoadBalancer update triggerred'
            LoadBalancer.update!
            @lb_update_hook = false
            Logger.notice 'LoadBalancer update finished'
          end
          sleep Config.lbaas[:interval]
          thr_safe(:swarm) { status_swarm = @status_swarm }
          # main logic
          if status_swarm
            # handle FloatingIP on leader
            Logger.debug 'I am the LEADER'
            if FloatingIP.up?
              Logger.debug 'Got FloatingIP, that is OK'
            else
              Logger.notice 'No FloatingIP here, checking whether it is free'
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
                  Logger.notice 'Notifying the network about change'
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
            Logger.debug 'I am a follower'
            if FloatingIP.up?
              Logger.notice 'I got FloatingIP and should not, removing'
              FloatingIP.handle! status_swarm
              FloatingIP.arp_del!
              Logger.notice 'Notifying the network about change'
              FloatingIP.update_arp!
            else
              Logger.debug 'No FloatingIP here, that is OK'
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
          Logger.notice 'Removing FloatingIP'
          FloatingIP.handle! false
          FloatingIP.update_arp!
        end

        # stop LB on shutdown
        if LoadBalancer.up?
          Logger.notice 'Stopping LoadBalancer'
          LoadBalancer.stop!
        end

        Logger.notice 'Exiting...'
        exit 0
      end

      def my_ip
        @my_ip ||= Socket.ip_address_list.detect(&:ipv4_private?).ip_address
      end

    end
  end
end
