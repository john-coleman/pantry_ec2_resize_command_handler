require 'spec_helper'
require_relative '../../pantry_ec2_resize_command_handler/pantry_ec2_resize_command_handler'

describe Wonga::Daemon::PantryEc2ResizeCommandHandler do
  let(:aws_resource) { instance_spy('Wonga::Daemon::AWSResource', stop: true, find_server_by_id: instance, status: instance.status) }
  let(:instance) { instance_spy('AWS::EC2::Instance', status: :running) }
  let(:logger) { instance_spy('Logger') }
  let(:publisher) { instance_double('Wonga::Daemon::Publisher', publish: true) }
  let(:error_publisher) { instance_double('Wonga::Daemon::Publisher', publish: true) }
  let(:message) do
    { 'flavor' =>  'm1.medium', 'id' => 1, 'instance_id' => 'i-ebf1a1a5' }
  end
  subject { Wonga::Daemon::PantryEc2ResizeCommandHandler.new(publisher, error_publisher, logger, aws_resource) }
  it_behaves_like 'handler'

  describe '#handle_message' do
    before(:each) do
      allow(aws_resource).to receive(:stop).with(message).and_return(true)
      allow(instance).to receive(:instance_type=).with(message['flavor'])
      allow(aws_resource).to receive(:find_server_by_id).and_return(instance)
    end

    context 'for terminated instance' do
      let(:instance) { instance_spy('AWS::EC2::Instance', status: :terminated) }

      it 'logs error message' do
        expect(logger).to receive(:error).with(/Instance is terminated/)
        subject.handle_message(message)
      end

      it 'publishes message to error topic' do
        subject.handle_message(message)
        expect(error_publisher).to have_received(:publish).with(message)
      end

      it 'does not publish message to event topic' do
        subject.handle_message(message)
        expect(publisher).to_not have_received(:publish)
      end
    end

    context 'for terminating instance' do
      let(:instance) { instance_spy('AWS::EC2::Instance', status: :shutting_down) }

      it 'logs error message' do
        expect(logger).to receive(:error).with(/Instance is shutting down/)
        subject.handle_message(message)
      end

      it 'publishes message to error topic' do
        subject.handle_message(message)
        expect(error_publisher).to have_received(:publish).with(message)
      end

      it 'does not publish message to event topic' do
        subject.handle_message(message)
        expect(publisher).to_not have_received(:publish)
      end
    end

    context 'for non-terminated instance' do
      it 'logs info message' do
        expect(logger).to receive(:info).with(/Stopping Instance/)
        subject.handle_message(message)
      end

      it 'stops the instance' do
        expect(aws_resource).to receive(:stop).with(message)
        subject.handle_message(message)
      end

      context 'instance can be stopped' do
        it 'logs info message' do
          expect(logger).to receive(:info).with(/Stopping Instance/)
          expect(logger).to receive(:info).with(/Instance stopped/)
          subject.handle_message(message)
        end

        it 'changes the instance_type' do
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
          allow(aws_resource).to receive(:stop).with(message).and_return(false)
        end

        it 'logs error message' do
          expect(logger).to receive(:error).with(/Instance could not be stopped/)
          subject.handle_message(message)
        end

        it 'does not publish message to error topic' do
          subject.handle_message(message)
          expect(error_publisher).to_not have_received(:publish)
        end

        it 'does not publish message to event topic' do
          subject.handle_message(message)
          expect(publisher).to_not have_received(:publish)
        end
      end
    end
  end
end
