require 'timeout'
require 'json'
require 'etcd-tools'
require 'port-authority/util/config'
require 'port-authority/util/logger'
require 'port-authority/util/helpers'

module PortAuthority
  module Manager
    class Init
      include PortAuthority::Util::Config
      include PortAuthority::Util::Logger
      include PortAuthority::Util::Helpers

      def initialize
        @config = { debug: false }
        @config = config
        @exit = false
        @semaphore = {
          log: Mutex.new,
        }
        @exit_sigs = %w(INT TERM)
        @exit_sigs.each { |sig| Signal.trap(sig) { info 'exit signal received, waiting for threads to exit...'; @exit = true } }
        Signal.trap('USR1') { @config[:debug] = false }
        Signal.trap('USR2') { @config[:debug] = true }
        Signal.trap('HUP')  { @config = config }
        Thread.current[:name] = 'main'
        info 'starting main thread'
      end

      def setup(proc_name, nice = -20)
        if RUBY_VERSION >= '2.1'
          Process.setproctitle(proc_name)
        else
          $0 = proc_name
        end
        Process.setpriority(Process::PRIO_PROCESS, 0, nice)
        # FIXME: Process.daemon ...
      end
    end
  end
end
