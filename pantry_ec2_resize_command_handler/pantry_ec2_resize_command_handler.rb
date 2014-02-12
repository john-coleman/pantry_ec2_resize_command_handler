module Wonga
  module Daemon
    class PantryEc2ResizeCommandHandler
      def initialize(publisher, logger, aws_resource)
        @publisher = publisher
        @logger = logger
        @aws_resource = aws_resource
      end

      def handle_message(message)
        @logger.info message.inspect
        return unless @aws_resource.stop(message)
        @logger.info "Instance stopped"
        ec2 = @aws_resource.find_server_by_id(message['instance_id'])
        ec2.instance_type = message["flavor"]
        @logger.info "Changed flavor and going to publish the event"
        @publisher.publish(message)
      end
    end
  end
end
