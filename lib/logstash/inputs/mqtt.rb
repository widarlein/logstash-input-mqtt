# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "stud/interval"
require "socket" # for Socket.gethostname
require "mqtt"


# Receive events from a MQTT topic

class LogStash::Inputs::Mqtt < LogStash::Inputs::Base
  config_name "mqtt"

  # The codec used for input data. Input codecs are a convenient method for decoding your data before it enters the input, without needing a separate filter in your Logstash pipeline.
  default :codec, "plain"

  # The host of the MQTT broker
  config :mqttHost, :validate => :string, :default => "localhost"

  # The port that the MQTT broker is using
  config :port, :validate => :number, :default => 1883

  # Whether connection to the MQTT broker is using SSL or not.
  config :ssl, :validate => :boolean, :default => false

  # The username for the MQTT connection
  config :username, :validate => :string, :default => nil

  # The password for the MQTT connection
  config :password, :validate => :string, :default => nil

  # The host of the MQTT broker
  config :client_id, :validate => :string, :default => MQTT::Client.generate_client_id("logstash-mqtt-input", 4)

  # Whether or not to use a clean session
  config :clean_session, :validate => :boolean, :default => true

  # The topic that the plugin should subscribe to
  config :topic, :validate => :string, :required => true

  # The topic qos that the plugin should subscribe with
  config :qos, :validate => :number, :default => 0

  public
  def register
    @host = Socket.gethostname
    @client = MQTT::Client.connect(
        :host => @mqttHost,
        :port => @port,
        :ssl => @ssl,
        :username => @username,
        :password => @password,
        :client_id => @client_id,
        :clean_session => @clean_session
    )
  end # def register

  def run(queue)

    @client.subscribe(@topic => @qos)
    @client.get do |topic,message|
        @codec.decode(message) do |event|
            host = event.get("host")
            host ||= @host
            event.set("host", host)
            
            event.set("topic", topic)

            decorate(event)
            queue << event
        end
    end
  end # def run

end # class LogStash::Inputs::Mqtt
