require 'spec_helper'
require_relative '../../pantry_ec2_resize_command_handler/pantry_ec2_resize_command_handler'

describe Wonga::Daemon::PantryEc2ResizeCommandHandler do
  let(:logger) { instance_double('Logger').as_null_object }
  let(:publisher) { instance_double('Wonga::Daemon::Publisher', publish: true) }
  let(:error_publisher) { instance_double('Wonga::Daemon::Publisher', publish: true) }
  let(:message) do
    { 'flavor' =>  'm1.medium', 'id' => 1, 'instance_id' => 'i-ebf1a1a5' }
  end
  let(:aws_resource) { instance_double('Wonga::Daemon::AWSResource') }
  subject { Wonga::Daemon::PantryEc2ResizeCommandHandler.new(publisher, error_publisher, logger, aws_resource) }
  it_behaves_like 'handler'

  describe '#handle_message' do
    describe 'when the instance is stopped' do
      before(:each) do
        allow(aws_resource).to receive(:stop).with(message).and_return(true)
        @instance = instance_double('AWS::EC2::Instance', status: true)
        allow(aws_resource).to receive(:find_server_by_id).and_return(@instance)
      end

      it 'changes the instance_type' do
        expect(@instance).to receive(:instance_type=).with(message['flavor'])
        allow(publisher).to receive(:publish)
        subject.handle_message(message)
      end

      it 'publishes the message' do
        allow(@instance).to receive(:instance_type=).with(message['flavor'])
        expect(publisher).to receive(:publish)
        subject.handle_message(message)
      end
    end
  end

  describe '#handle_message publishes message to error topic for terminated instance' do
    let(:instance) { instance_double('AWS::EC2::Instance', status: :terminated).as_null_object }
    let(:aws_resource) { instance_double('Wonga::Daemon::AWSResource', stop: true, find_server_by_id: 'i-ebf1a1a5', status: 'i-ebf1a1a5') }

    before(:each) do
      allow(aws_resource).to receive(:find_server_by_id).and_return(instance)
    end

    it 'publishes message to error topic' do
      subject.handle_message(message)
      expect(error_publisher).to have_received(:publish).with(message)
    end

    it 'does not publish message to topic' do
      subject.handle_message(message)
      expect(publisher).to_not have_received(:publish)
    end
  end
end
