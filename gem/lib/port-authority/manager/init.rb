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

      def initialize(proc_name = 'dummy')
        @semaphore = { log: Mutex.new }
        @config = config
        @exit = false
        Thread.current[:name] = 'main'
        syslog_init proc_name if @config[:syslog]
        setup proc_name
        info 'starting main thread'
        debug 'setting signal handling'
        @exit_sigs = %w(INT TERM)
        @exit_sigs.each { |sig| Signal.trap(sig) { @exit = true } }
        Signal.trap('USR2') do
          if @config[:debug]
            @config[:debug] = false
          else
            @config[:debug] = true
          end
        end
        Signal.trap('HUP') { @config = config }
      end

      def setup(proc_name, nice = -20)
        debug 'setting process name'
        if RUBY_VERSION >= '2.1'
          Process.setproctitle(proc_name)
        else
          $0 = proc_name
        end
        debug 'setting process title'
        Process.setpriority(Process::PRIO_PROCESS, 0, nice)
        # FIXME: Process.daemon ...
      end
    end
  end
end
