# frozen_string_literal: true

require_relative "../spec_helper"
require "mqtt"
require "timeout"

mqtt_hosts = inventory.all_hosts_in("mqtt")
# XXX when we have CA, set path to ca.pem here
ca_pem = nil

# XXX some topics under $SYS are returned immediately, others are not.
#
# Topics marked as static are only sent once per client on subscription. All
# other topics are updated every sys_interval seconds.
def get_message(mqtt_client, topic)
  result = nil
  begin
    Timeout.timeout(10) do
      mqtt_client.get do |t, m|
        result = m if t == topic
      end
    end
  rescue Timeout::Error
    # NOOP
  end
  result
end

mqtt_hosts.each do |mqtt_host|
  describe mqtt_host do
    context "when port is MQTT/SSL" do
      let(:mqtt_client) do
        MQTT::Client.new(
          host: inventory.host(mqtt_host)["ansible_host"],
          port: 8883,
          ssl: true,
          ca_file: ca_pem
        )
      end

      before(:example) { mqtt_client.connect }
      after(:example) { mqtt_client.disconnect }

      context "when the user is anonymous" do
        it "allows the user to subscribe $SYS/# and read $SYS/broker/bytes/sent" do
          expect { mqtt_client.subscribe("$SYS/#") }.not_to raise_error
          expect(get_message(mqtt_client, "$SYS/broker/bytes/sent")).to match(/^\d+$/)
        end

        it "does not allow to read $SYS/broker/uptime" do
          expect { mqtt_client.subscribe("$SYS/#") }.not_to raise_error
          expect(get_message(mqtt_client, "$SYS/broker/uptime")).not_to match(/^\d+ \S+$/)
        end
      end
    end

    context "when port is MQTT" do
      let(:mqtt_client) do
        MQTT::Client.new(
          host: inventory.host(mqtt_host)["ansible_host"],
          port: 1883,
          ssl: false
        )
      end

      before(:example) { mqtt_client.connect }
      after(:example) { mqtt_client.disconnect }

      context "when the user is anonymous" do
        it "allows the user to subscribe $SYS/# and read $SYS/broker/bytes/sent" do
          expect { mqtt_client.subscribe("$SYS/#") }.not_to raise_error
          expect(get_message(mqtt_client, "$SYS/broker/bytes/sent")).to match(/^\d+$/)
        end

        it "does not allow to read $SYS/broker/uptime" do
          expect { mqtt_client.subscribe("$SYS/#") }.not_to raise_error
          expect(get_message(mqtt_client, "$SYS/broker/uptime")).not_to match(/^\d+ \S+$/)
        end
      end
    end
  end
end
