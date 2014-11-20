#!/usr/bin/env ruby
require 'rubygems'
require 'wonga/daemon'
require 'wonga/daemon/aws_resource'
require_relative 'pantry_ec2_resize_command_handler/pantry_ec2_resize_command_handler'

config_name = File.join(File.dirname(File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__), 'config', 'daemon.yml')
Wonga::Daemon.load_config(File.expand_path(config_name))
Wonga::Daemon.run(Wonga::Daemon::PantryEc2ResizeCommandHandler.new(
  Wonga::Daemon.publisher,
  Wonga::Daemon.error_publisher,
  Wonga::Daemon.logger,
  Wonga::Daemon::AWSResource.new)
)
