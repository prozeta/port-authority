# rubocop:disable Metrics/MethodLength
module PortAuthority
  module Manager
    module Threads
      def thread_swarm
        Thread.new do
          Thread.current[:name] = 'swarm'
          info 'starting swarm thread...'
          begin
            etcd = etcd_connect!
            until @exit
              debug 'checking ETCD state'
              etcd_healthy? etcd
              debug 'checking swarm state'
              status = am_i_leader? etcd
              @semaphore[:swarm].synchronize { @status_swarm = status }
              debug "i am #{status ? 'the leader' : 'not the leader' }"
              sleep @config[:etcd][:interval]
            end
            info 'ending swarm thread...'
          rescue PortAuthority::Errors::ETCDIsSick => e
            notice "#{e.class}: #{e.message}"
            notice "connection: " + e.etcd.to_s
            @semaphore[:swarm].synchronize { @status_swarm = false }
            sleep @config[:etcd][:interval]
            retry unless @exit
          rescue PortAuthority::Errors::ETCDConnectFailed => e
            err "#{e.class}: #{e.message}"
            err "connection: " + e.etcd.to_s
            @semaphore[:swarm].synchronize { @status_swarm = false }
            sleep @config[:etcd][:interval]
            retry unless @exit
          rescue StandardError => e
            alert e.message
            alert e.backtrace.to_s
            @exit = true
          end
        end
      end
    end
  end
end
