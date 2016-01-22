# rubocop:disable Metrics/MethodLength
module PortAuthority
  module Manager
    module Threads
      def thread_swarm
        Thread.new do
          debug 'starting swarm thread...'
          etcd = etcd_connect!
          until @exit
            debug 'checking swarm state'
            status = am_i_leader? etcd
            @semaphore[:swarm].synchronize { @status_swarm = status }
            debug "i am #{status ? 'the leader' : 'not the leader' }"
            sleep @config[:etcd][:interval]
          end
          info 'ending swarm thread...'
        end
      end
    end
  end
end
