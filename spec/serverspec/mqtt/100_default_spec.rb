# frozen_string_literal: true

require_relative "../spec_helper"
require "net/http"

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

describe command "monit status mosquitto" do
  # XXX use retry here because monit and mosquitto need some time to start up
  it "says monit is monitroing mosquitto", retry: 3, retry_wait: 10 do
    command = command("monit status mosquitto")

    expect(command.exit_status).to eq 0
    expect(command.stderr).to eq ""
    expect(command.stdout).to match(/monitoring mode\s+active/)
    expect(command.stdout).to match(/monitoring status\s+Monitored/)
  end
end
