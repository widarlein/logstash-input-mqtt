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
  config :mqttHost, :validate => :string, :default => "localhost", :required => true
  
  # The port that the MQTT broker is using
  config :port, :validate => :number, :default => 1883, :required => true
  
  # Whether connection to the MQTT broker is using SSL or not.
  config :ssl, :validate => :boolean, :default => false
  
  # The topic that the plugin should subscribe to
  config :topic, :validate => :string, :required => true

  public
  def register
    @host = Socket.gethostname
    @client = MQTT::Client.connect(
        :host => @mqttHost,
        :port => @port,
        :ssl => @ssl,
        :client_id => MQTT::Client.generate_client_id("logstash-mqtt-input", 4)
    )
  end # def register

  def run(queue)

    @client.subscribe(@topic)
    @client.get do |topic,message|
        @codec.decode(message) do |event|
            event["host"] ||= @host
            event["topic"] = topic
            
            decorate(event)
            queue << event
        end
    end
  end # def run

end # class LogStash::Inputs::Mqtt