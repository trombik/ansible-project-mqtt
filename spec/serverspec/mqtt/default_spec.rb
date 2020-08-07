# frozen_string_literal: true

require_relative "../spec_helper"
require "net/http"

ports = [
  1883 # mosquitto
]
services = %w[
  monit
  mosquitto
]

context "after provision finishes" do
  it_behaves_like "a host with a valid hostname"
  it_behaves_like "a host with all basic tools installed"
end

services.each do |s|
  describe service s do
    it { should be_enabled }
    it { should be_running }
  end
end

ports.each do |p|
  describe port p do
    it { should be_listening }
  end
end

describe command "monit status mosquitto" do
  # XXX use retry here because monit and mosquitto need some time to start up
  it "says monit is monitroing mosquitto", retry: 3, retry_wait: 10 do
    command = command("monit status mosquitto")

    expect(command.exit_status).to eq 0
    expect(command.stderr).to eq ""
    expect(command.stdout).to match(/monitoring mode\s+active/)
  end
end

topic = "$SYS/broker/clients/connected"
describe "mosquitto_sub" do
  it "returns #{topic}", retry: 3, retry_wait: 10 do
    command = command("mosquitto_sub -h 127.0.0.1 -C 1 -t #{Shellwords.escape(topic)}")

    expect(command.exit_status).to eq 0
    expect(command.stderr).to eq ""
    expect(command.stdout).to match(/^\d+$/)
  end
end
