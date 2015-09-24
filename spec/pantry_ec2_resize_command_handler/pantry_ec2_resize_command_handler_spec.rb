require 'spec_helper'
require_relative '../../pantry_ec2_resize_command_handler/pantry_ec2_resize_command_handler'
require 'wonga/daemon/aws_resource'
require 'wonga/daemon/publisher'

RSpec.describe Wonga::Daemon::PantryEc2ResizeCommandHandler do
  let(:logger) { instance_spy(Logger) }
  let(:publisher) { instance_double(Wonga::Daemon::Publisher, publish: true) }
  let(:error_publisher) { instance_double(Wonga::Daemon::Publisher) }
  let(:message) do
    { 'flavor' =>  'm1.medium', 'id' => 1, 'instance_id' => 'i-ebf1a1a5' }
  end
  let(:aws_resource) { Wonga::Daemon::AWSResource.new(error_publisher, logger, aws_ec2_resource) }

  subject { Wonga::Daemon::PantryEc2ResizeCommandHandler.new(publisher, logger, aws_resource) }
  it_behaves_like 'handler'
  let(:instance_response) { { reservations: [{ instances: [instance_attributes] }] } }
  let(:instance_attributes) { { instance_id: '100100', instance_type: 'm3.large' } }
  let(:aws_ec2_resource) { Aws::EC2::Resource.new }

  before(:each) do
    aws_ec2_resource.client.stub_responses(:describe_instances, instance_response)
  end

  describe '#handle_message' do
    context 'instance can be stopped' do
      before(:each) do
        allow(aws_resource).to receive(:stop).and_return(true)
      end

      it 'changes the instance_type' do
        expect(aws_ec2_resource.client).to receive(:modify_instance_attribute).with(hash_including(instance_type: { value: 't2.medium' }))
        allow(publisher).to receive(:publish)
        subject.handle_message(message)
      end

      it 'publishes the message' do
        expect(publisher).to receive(:publish)
        subject.handle_message(message)
      end
    end

    context 'instance cannot be stopped' do
      before(:each) do
        allow(aws_resource).to receive(:stop).and_return(false)
      end

      it 'does not change instance type' do
        expect(aws_ec2_resource.client).not_to receive(:modify_instance_attribute)
        subject.handle_message(message)
      end

      it 'does not publish message to event topic' do
        subject.handle_message(message)
        expect(publisher).to_not have_received(:publish)
      end
    end
  end
end
