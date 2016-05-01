require 'optparse'
require 'json'
require 'yaml'
require 'etcd-tools'
# require 'etcd-tools/mixins'
require 'port-authority/etcd'
require 'port-authority/tool'

module PortAuthority
  module Tools
    class ServiceList < PortAuthority::Tool

      attr_reader :etcd

      def optparse
        @options = Hash.new
        @options[:url] = ENV['ETCDCTL_ENDPOINT']
        @options[:url] ||= "http://127.0.0.1:2379"
        @options[:output_yaml] = false
        @options[:output_json] = false
        @options[:ip_only] = false
        @options[:ports] = false
        @options[:service_filter] = '.*'

        OptionParser.new do |opts|
          opts.banner = "Lists\n\nUsage: #{$0} [OPTIONS] NETWORK_NAME"
          opts.separator ""
          opts.separator "Connection options:"
          opts.on("-u", "--url URL", "URL endpoint of the ETCD service (ETCDCTL_ENDPOINT envvar also applies) [DEFAULT: http://127.0.0.1:2379]") do |param|
            @options[:url] = param
          end

          opts.separator ""
          opts.separator "Filter options:"
          opts.on("-s SERVICE_NAME", "--service-filter SERVICE_NAME", String, "List only services by name") do |param|
            @options[:service_filter] = param
          end

          opts.separator ""
          opts.separator "Output options:"
          opts.on("-i", "--ips", "List only IPs (text mode)") do
            @options[:ip_only] = true
          end
          opts.on("-p", "--ports", "List exposed ports (text mode)") do
            @options[:ports] = true
          end
          opts.on("-y", "--yaml", "Output the data as YAML") do
            @options[:output_yaml] = true
          end
          opts.on("-j", "--json", "Output the data as JSON") do
            @options[:output_json] = true
          end

          opts.separator ""
          opts.separator "Common options:"
          opts.on_tail("-h", "--help", "show usage") do |param|
            puts opts
            exit! 0
          end
        end.parse!
      end

      def run
        unless @ARGS[0]
          $stderr.puts 'Missing NETWORK_NAME!'
          exit 1
        end

        @etcd = PortAuthority::Etcd.shell_cluster_connect(@options[:url])

        services = @etcd.swarm_list_services(@ARGS[0], @options[:service_filter])

        if @options[:output_yaml]
          puts services.to_yaml
        elsif @options[:output_json]
          puts services.to_json
        else
          if @options[:ip_only]
            services.each { |_, params| puts params['ip'] }
          elsif @options[:ports]
            services.each do |name, params|
              params['ports'].each do |port|
                puts "#{name} #{params['ip']}:#{port}"
              end
            end
          else
            services.each { |name, params| puts "#{name} #{params['ip']}" }
          end
        end
      end
    end
  end
end
