# rubocop:disable Metrics/LineLength, Metrics/AbcSize, Metrics/MethodLength
require 'syslog'

module PortAuthority
  module Logger

    extend self

    def init!(s)
      @_s = s
      @debug = Config.debug
      Syslog.open($0, Syslog::LOG_PID, Syslog::LOG_DAEMON) if Config.syslog
    end

    def debug!
      @debug = !@debug
    end

    def debug(message)
      log :debug, message if @debug
    end

    def method_missing(name, *args, &_block)
      if name
        return log(name.to_sym, args[0])
      else
        fail(NoMethodError, "Unknown Logger method '#{name}'", caller)
      end
    end

    def log(lvl, msg)
      if Config.syslog
        case lvl
        when :debug
          l = Syslog::LOG_DEBUG
        when :info
          l = Syslog::LOG_INFO
        when :notice
          l = Syslog::LOG_NOTICE
        when :error
          l = Syslog::LOG_ERR
        when :alert
          l = Syslog::LOG_ALERT
        end
        @_s.synchronize do
          Syslog.log(l, "(%s) %s", Thread.current[:name], msg.to_s)
        end
      else
        @_s.synchronize do
          $stdout.puts [Time.now.to_s, sprintf('%-6.6s', lvl.to_s.upcase), "(#{Thread.current[:name]})", msg.to_s].join(' ')
          $stdout.flush
        end
      end
    end
  end
end
