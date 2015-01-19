module Wonga
  module Daemon
    class PantryEc2ResizeCommandHandler
      def initialize(publisher, error_publisher, logger, aws_resource)
        @publisher = publisher
        @error_publisher = error_publisher
        @logger = logger
        @aws_resource = aws_resource
      end

      def handle_message(message)
        ec2 = @aws_resource.find_server_by_id(message['instance_id'])
        if ec2.status == :terminated || ec2.status == :shutting_down
          @logger.error "Instance is #{ec2.status.to_s.gsub(/_/, ' ')}: #{message.inspect}"
          send_error_message(message)
          return
        end
        @logger.info "Stopping Instance: #{message.inspect}"
        unless @aws_resource.stop(message)
          @logger.error "Instance could not be stopped: #{message.inspect}"
          return
        end
        @logger.info "Instance stopped: #{message.inspect}"
        old_flavor = ec2.instance_type
        ec2.instance_type = message['flavor']
        @logger.info "Flavor changed from #{old_flavor} to #{message['flavor']}: #{message.inspect}"
        @publisher.publish(message)
      end

      def send_error_message(message)
        @logger.info "Send request to cleanup instance #{message.inspect}"
        @error_publisher.publish(message)
      end
    end
  end
end
