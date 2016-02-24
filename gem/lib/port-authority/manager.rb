# rubocop:disable MethodLength, CyclomaticComplexity, Metrics/BlockNesting, Metrics/LineLength, Metrics/AbcSize, Metrics/PerceivedComplexity
require 'ipaddr'
require 'port-authority'
require 'port-authority/util/vip'
require 'port-authority/util/etcd'
require 'port-authority/util/loadbalancer'
require 'port-authority/manager/init'
require 'port-authority/manager/threads/icmp'
require 'port-authority/manager/threads/swarm'

module PortAuthority
  module Manager
    ##
    # Port Authority Manager - manages floating VIP and lb placement
    #
    class App < PortAuthority::Manager::Init
      include PortAuthority::Util::Etcd
      include PortAuthority::Util::Vip
      include PortAuthority::Util::LoadBalancer
      include PortAuthority::Manager::Threads

      def run
        # exit if not root
        if Process.euid != 0
          alert 'must run under root user!'
          exit! 1
        end

        Signal.trap('USR1') { @lb_update_hook = true }

        # prepare semaphores
        @semaphore.merge!(swarm: Mutex.new, icmp: Mutex.new)

        # prepare threads
        @thread = {icmp: thread_icmp,swarm: thread_swarm}

        # prepare status vars
        @status_swarm = false
        @status_icmp = false

        # start threads
        @thread.each_value(&:run)

        # setup docker client
        lb_docker_setup! || @exit = true

        # prepare container with load-balancer
        lb_create!

        # wait for threads to make sure they gather something
        debug 'waiting for threads to gather something...'
        sleep @config[:vip][:interval]
        first_cycle = true
        status_time = Time.now.to_i - 60

        # main loop
        until @exit
          # initialize local state vars on first iteration
          status_swarm = status_icmp = false if first_cycle

          if @lb_update_hook
            notice 'updating LB image'
            lb_update!
          end

          # iteration interval
          sleep @config[:vip][:interval]

          # sync state to local variables
          @semaphore[:icmp].synchronize { status_icmp = @status_icmp }
          @semaphore[:swarm].synchronize { status_swarm = @status_swarm }

          # the logic (should be self-explanatory ;))
          if status_swarm
            debug 'i am the leader'
            if got_vip?
              debug 'got VIP, that is OK'
            else
              info 'no VIP here, checking whether it is free'
              if status_icmp
                info 'VIP is still up! (ICMP)'
                # FIXME: notify by sensu client socket
              else
                # FIXME: proper arping handling
                # info 'VIP is unreachable by ICMP, checking for duplicates on L2'
                # if vip_dup?
                #   info 'VIP is still assigned! (ARP)'
                #   # FIXME: notify by sensu client socket
                # else
                #   info 'VIP is free :) assigning'
                #   vip_handle! status_swarm
                #   info 'updating other hosts about change'
                #   vip_update_arp!
                # end
                notice 'VIP is free :) assigning'
                vip_handle! status_swarm
                notice 'updating other hosts about change'
                vip_update_arp!
              end
            end
            if lb_up?
              debug 'load-balancer is up, that is OK'
            else
              notice 'load-balancer is down, starting'
              lb_start!
            end
          else
            debug 'i am not the leader'
            if got_vip?
              notice 'i got VIP and should not, removing'
              vip_handle! status_swarm
              notice 'updating other hosts about change'
              vip_update_arp!
            else
              debug 'no VIP here, that is OK'
            end
            if lb_up?
              notice 'load-balancer is up, stopping'
              lb_stop!
            else
              debug 'load-balancer is down, that is OK'
            end
          end

          if status_time + 60 <= Time.now.to_i
            info "STATUS_REPORT { leader: '#{status_swarm ? 'yes' : 'no'}', vip: '#{got_vip? ? 'yes' : 'no'}/#{status_icmp ? 'up' : 'down'}', lb: '#{lb_up? ? 'yes' : 'no'}' }"
            status_time = Time.now.to_i
          end

        end

        # this is triggerred on exit
        @thread.each_value(&:join)

        # remove VIP on shutdown
        if got_vip?
          notice 'removing VIP'
          vip_handle! false
          vip_update_arp!
        end

        # stop LB on shutdown
        if lb_up?
          notice 'stopping load-balancer'
          lb_stop!
        end

        info 'exiting...'
        exit 0
      end
    end
  end
end
