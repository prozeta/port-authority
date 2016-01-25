# rubocop:disable Metrics/LineLength, Metrics/AbcSize, Metrics/MethodLength
require 'logger'

module PortAuthority
  module Util
    module Logger
      def info(message)
        @semaphore[:log].synchronize do
          $stdout.puts("#{Time.now.to_s} I (#{Thread.current[:name]}) #{message.to_s}")
          $stdout.flush
        end
      end

      def err(message)
        @semaphore[:log].synchronize do
          $stdout.puts("#{Time.now.to_s} E (#{Thread.current[:name]}) #{message.to_s}")
          $stdout.flush
        end
      end

      def debug(message)
        @semaphore[:log].synchronize do
          $stdout.puts("#{Time.now.to_s} D (#{Thread.current[:name]}) #{message.to_s}")
          $stdout.flush
        end if @config[:debug]
      end
    end
  end
end
