# rubocop:disable Metrics/LineLength, Metrics/AbcSize, Metrics/MethodLength
require 'syslog'

module PortAuthority
  module Util
    module Logger
      def debug(message)
        log :debug, message if @config[:debug]
      end

      def info(message)
        log :info, message
      end

      def notice(message)
        log :notice, message
      end

      def err(message)
        log :err, message
      end

      def alert(message)
        log :alert, message if @config[:debug]
      end

      def syslog_init(proc_name)
        Syslog.open(proc_name, Syslog::LOG_PID, Syslog::LOG_DAEMON)
      end

      def log(lvl, msg)
        if @config[:syslog]
          case lvl
          when :debug
            l = Syslog::LOG_DEBUG
          when :info
            l = Syslog::LOG_INFO
          when :notice
            l = Syslog::LOG_NOTICE
          when :err
            l = Syslog::LOG_ERR
          when :alert
            l = Syslog::LOG_ALERT
          end
          @semaphore[:log].synchronize do
            Syslog.log(l, "(%s) %s", Thread.current[:name], msg.to_s)
          end
        else
          @semaphore[:log].synchronize do
            $stdout.puts("#{Time.now.to_s} #{lvl.to_s[0].capitalize} (#{Thread.current[:name]}) #{msg.to_s}")
            $stdout.flush
          end
        end
      end
    end
  end
end
