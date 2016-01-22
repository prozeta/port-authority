# rubocop:disable Metrics/LineLength, Metrics/AbcSize, Metrics/MethodLength
require 'logger'

module PortAuthority
  module Util
    module Logger
      def info(message)
        if @config[:debug]
          @semaphore[:log].synchronize do
            $stdout.puts(Time.now.to_s + ' INFO  (TID:' + Thread.current.object_id.to_s + ') ' + message.to_s)
            $stdout.flush
          end
        else
          @semaphore[:log].synchronize do
            $stdout.puts(Time.now.to_s + ' INFO  ' + message.to_s)
            $stdout.flush
          end
        end
      end

      def err(message)
        if @config[:debug]
          @semaphore[:log].synchronize do
            $stdout.puts(Time.now.to_s + ' ERROR (TID:' + Thread.current.object_id.to_s + ') ' + message.to_s)
            $stdout.flush
          end
        else
          @semaphore[:log].synchronize do
            $stdout.puts(Time.now.to_s + ' ERROR ' + message.to_s)
            $stdout.flush
          end
        end
      end

      def debug(message)
        @semaphore[:log].synchronize do
          $stdout.puts(Time.now.to_s + ' DEBUG (TID:' + Thread.current.object_id.to_s + ') ' + message.to_s)
          $stdout.flush
        end if @config[:debug]
      end
    end
  end
end
