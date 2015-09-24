module Wonga
  module Daemon
    class PantryEc2ResizeCommandHandler
      def initialize(publisher, logger, aws_resource)
        @publisher = publisher
        @logger = logger
        @aws_resource = aws_resource
      end

      def handle_message(message)
        return unless @aws_resource.stop(message)

        ec2_instance = @aws_resource.find_server_by_id(message['instance_id'])
        old_flavor = ec2_instance.instance_type
        ec2_instance.modify_attribute(instance_type: { value: 't2.medium' })
        @logger.info "Flavor changed from #{old_flavor} to #{message['flavor']}: #{message.inspect}"
        @publisher.publish(message)
      end
    end
  end
end
