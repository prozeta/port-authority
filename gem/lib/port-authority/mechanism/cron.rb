require 'docker-api'

module PortAuthority
  module Mechanism
    module Cron

      extend self

      attr_reader :_container, :_container_def, :_image

      def init!
        Docker.url = Config.cron[:docker_endpoint]
        Docker.options = { connect_timeout: Config.cron[:docker_timeout] || 10 }
        self.container || ( self.pull! && self.create! )
      end

      def container
        @_container ||= Docker::Container.get(Config.cron[:name]) rescue nil
      end

      def image
        @_image ||= Docker::Image.create('fromImage' => Config.cron[:image])
      end

      def pull!
        @_image = Docker::Image.create('fromImage' => Config.cron[:image])
      end

      def create!
        @_container_def = {
          'Image' => self.image.json['Id'],
          'name' => Config.cron[:name],
          'Hostname' => Config.cron[:name],
          'Env' => [ "ETCDCTL_ENDPOINT=#{Config.etcd[:endpoints].join(',')}","#{Config.cron[:env]}" ],
          'RestartPolicy' => { 'Name' => 'never' },
          'HostConfig' => {
            'Binds' => [ "#{Config.cron[:folder]}" ],
            'NetworkMode' => Config.cron[:network]
          }
        }
        if Config.cron[:log_dest] != ''
          @_container_def['HostConfig']['LogConfig'] = {
            'Type' => 'gelf',
            'Config' => {
              'gelf-address' => Config.cron[:log_dest],
              'tag' =>  Socket.gethostbyname(Socket.gethostname).first + '/{{.Name}}/{{.ID}}'
            }
          }
        end
        @_container = Docker::Container.create(@_container_def)
      end


      def update!
        begin
          ( self.stop! && start = true ) if self.up?
          self.remove!
          self.pull!
          self.create!
          self.start! if start == true
        rescue StandardError => e
          Logger.error "UNCAUGHT EXCEPTION IN THREAD #{Thread.current[:name]}"
          Logger.error [' ', e.class, e.message].join(' ')
          Logger.error '  ' + e.backtrace.to_s
        end
      end

      def remove!
        @_container.delete
      end

      def up?
        @_container.json['State']['Running']
      end

      def start!
        @_container.start
      end

      def stop!
        @_container.stop
      end

    end
  end
end
