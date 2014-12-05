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
        if ec2.status == :terminated
          send_error_message(message)
          return
        end
        ec2.instance_type = message['flavor']
        @logger.info 'Flavor changed'
        @publisher.publish(message)
      end

      def send_error_message(message)
        @logger.info 'Send request to cleanup an instance'
        @error_publisher.publish(message)
      end
    end
  end
end
