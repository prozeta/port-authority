require 'ipaddr'
require 'port-authority/util/vip'
require 'port-authority/util/etcd'
require 'port-authority/util/loadbalancer'
require 'port-authority/manager/init'
require 'port-authority/manager/threads/icmp'
require 'port-authority/manager/threads/swarm'

module PortAuthority
  module Manager
    class App < PortAuthority::Manager::Init

      include PortAuthority::Util::Etcd
      include PortAuthority::Util::Vip
      include PortAuthority::Util::LoadBalancer
      include PortAuthority::Manager::Threads

      def run
        # exit if not root
        if Process.euid != 0
          $stderr.puts 'Must run under root user!'
          exit! 1
        end

        # set process name and nice level (default: -20)
        setup 'pa-manager'

        # prepare semaphores
        @semaphore = {
          log: Mutex.new,
          swarm: Mutex.new,
          icmp: Mutex.new
        }

        # prepare threads
        @thread = {
          icmp: thread_icmp,
          swarm: thread_swarm
        }

        # prepare status vars
        @status_swarm = false
        @status_icmp = false

        # start threads
        @thread.each_value(&:run)

        # setup docker client
        lb_docker_setup! || @exit = true

        # prepare container with load-balancer
        lb_create || @exit = true

        # wait for threads to make sure they gather something
        debug 'waiting for threads to gather something...'
        sleep @config[:vip][:interval]
        first_cycle = true

        # main loop
        until @exit
          # initialize local state vars on first iteration
          status_swarm = status_icmp = false if first_cycle

          # iteration interval
          sleep @config[:vip][:interval]

          # sync state to local variables
          @semaphore[:icmp].synchronize { status_icmp = @status_icmp }
          @semaphore[:swarm].synchronize { status_swarm = @status_swarm }

          # the logic (should be self-explanatory ;))
          if status_swarm
            if got_vip?
              debug 'i am the leader with VIP, that is OK'
            else
              info 'i am the leader without VIP, checking whether it is free'
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
              end
              info 'VIP is free :) assigning'
              vip_handle! status_swarm
              info 'updating other hosts about change'
              vip_update_arp!
            end
            if lb_up?
              debug 'i am the leader and load-balancer is up, that is OK'
            else
              info 'i am the leader and load-balancer is down, starting'
              lb_start!
            end
          else
            if got_vip?
              info 'i got VIP and should not, removing'
              vip_handle! status_swarm
              info 'updating other hosts about change'
              vip_update_arp!
            else
              debug 'i am not the leader and i do not have the VIP, that is OK'
            end
            if lb_up?
              info 'i am not the leader and load-balancer is up, stopping'
              lb_stop!
            else
              debug 'i am not the leader and load-balancer is down, that is OK'
            end
          end

          next unless first_cycle

          # short report on first cycle
          info "i #{status_swarm ? 'AM' : 'am NOT'} the leader"
          info "i #{got_vip? ? 'DO' : 'do NOT'} have the VIP"
          info "i #{status_icmp ? 'CAN' : 'CANNOT'} see the VIP"
          info "i #{lb_up? ? 'AM' : 'am NOT'} running the LB"
          first_cycle = false
        end

        # this is triggerred on exit
        info 'SIGTERM received'
        info 'waiting for threads to finish...'
        @thread.each_value(&:join)

        # remove VIP on shutdown
        if got_vip?
          info 'removing VIP'
          vip_handle! false
          vip_update_arp!
        end

        # stop LB on shutdown
        if lb_up?
          info 'stopping load-balancer'
          lb_stop!
        end

        info 'exiting...'
        exit 0
      end


    end
  end
end
