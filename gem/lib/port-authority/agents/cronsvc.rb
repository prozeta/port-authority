# rubocop:disable MethodLength, CyclomaticComplexity, Metrics/BlockNesting, Metrics/LineLength, Metrics/AbcSize, Metrics/PerceivedComplexity
require 'socket'
require 'port-authority/agent'
require 'port-authority/mechanism/cron'

module PortAuthority
  module Agents
    class CronSvc < PortAuthority::Agent
      include PortAuthority::Mechanism

      def run
        setup(daemonize: Config.daemonize, nice: -10, root: true)
        Signal.trap('HUP') { Config.load! && Cron.init! }
        Signal.trap('USR1') { Logger.debug! }
        Signal.trap('USR2') { @cron_update_hook = true }
        @status_swarm = false
        @etcd = PortAuthority::Etcd.cluster_connect Config.etcd

        thr_create(:swarm, Config.cron[:swarm_interval] || Config.cron[:interval]) do
          begin
            Logger.debug 'Checking Swarm state'
            status = @etcd.am_i_swarm_leader?
            thr_safe { @status_swarm = status }
            Logger.debug "I am Swarm #{status ? 'leader' : 'follower' }"
          rescue StandardError => e
            Logger.error [ e.class, e.message ].join(': ')
            e.backtrace.each {|line| Logger.debug "  #{line}"}
            thr_safe { @status_swarm = false }
            sleep(Config.cron[:swarm_interval] || Config.cron[:interval])
            retry unless exit?
          end
        end

        thr_start

        Cron.init!

        Logger.debug 'Waiting for threads to gather something...'
        sleep Config.cron[:interval]
        first_cycle = true
        status_time = Time.now.to_i - 60

        until exit?
          status_swarm = false if first_cycle
          if @cron_update_hook
            Logger.notice 'Cron update triggerred'
            Cron.update!
            @cron_update_hook = false
            Logger.notice 'Cron update finished'
          end
          sleep Config.cron[:interval]
          thr_safe(:swarm) { status_swarm = @status_swarm }
          # main logic
          if status_swarm
            # handle FloatingIP on leader
            Logger.debug 'I am the LEADER'
            # handle LoadBalancer on leader
            if Cron.up?
              Logger.debug 'Cron is up, that is OK'
            else
              Logger.notice 'Cron is down, starting'
              Cron.start!
            end
          else
            # handle LoadBalancer on follower
            if Cron.up?
              Logger.notice 'Cron is up, stopping'
              Cron.stop!
            else
              Logger.debug 'Cron is down, that is OK'
            end
          end # logic end
        end

        thr_wait

        # stop LB on shutdown
        if Cron.up?
          Logger.notice 'Stopping Cron'
          Cron.stop!
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
