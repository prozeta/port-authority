require 'timeout'
require 'json'
require 'etcd-tools'
require 'port-authority/util/config'
require 'port-authority/util/logger'
require 'port-authority/util/helpers'

module PortAuthority
  module Watchdog
    class Init

      include PortAuthority::Util::Config
      include PortAuthority::Util::Logger
      include PortAuthority::Util::Helpers

      def initialize
        @config = { debug: false }
        @config = config
        @exit = false
        @exit_sigs = ['INT', 'TERM']
        @exit_sigs.each { |sig| Signal.trap(sig) { @exit = true } }
        Signal.trap('USR1') { @config[:debug] = false }
        Signal.trap('USR2') { @config[:debug] = true }
        Signal.trap('HUP')  { @config = config }
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
