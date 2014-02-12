require 'spec_helper'
require_relative '../../pantry_ec2_resize_command_handler/pantry_ec2_resize_command_handler'

describe Wonga::Daemon::PantryEc2ResizeCommandHandler do
  let(:logger) { instance_double('Logger').as_null_object }
  let(:publisher) { instance_double('Wonga::Daemon::Publisher') }
  let(:message) {
    {"flavor" =>  "m1.medium", "id" => 1, "instance_id" => "i-ebf1a1a5"}
  }
  let(:aws_resource) { instance_double('Wonga::Daemon::AWSResource.new') }
  subject { Wonga::Daemon::PantryEc2ResizeCommandHandler.new(publisher, logger, aws_resource) }
  it_behaves_like 'handler'

  describe "#handle_message" do
    it "exits when the instance is terminated or not found" do
      expect(aws_resource).to receive(:stop).with(message).and_return(nil)
      subject.handle_message(message)
    end

    describe "when the instance is stopped" do
      before(:each) do
        allow(aws_resource).to receive(:stop).with(message).and_return(true)
        @instance = instance_double('AWS::EC2::Instance')
        allow(aws_resource).to receive(:find_server_by_id).and_return(@instance)
      end

      it "changes the instance_type " do
        expect(@instance).to receive(:instance_type=).with(message["flavor"])
        allow(publisher).to receive(:publish)
        subject.handle_message(message)
      end

      it "publishes the message" do
        allow(@instance).to receive(:instance_type=).with(message["flavor"])
        expect(publisher).to receive(:publish)
        subject.handle_message(message)
      end
    end
  end
end

