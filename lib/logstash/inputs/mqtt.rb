# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "stud/interval"
require "socket" # for Socket.gethostname
require "mqtt"

# Generate a repeating message.
#
# This plugin is intented only as an example.

class LogStash::Inputs::Mqtt < LogStash::Inputs::Base
  config_name "mqtt"

  # If undefined, Logstash will complain, even if codec is unused.
  default :codec, "plain" 

  # The message string to use in the event.
  config :message, :validate => :string, :default => "Hello World!"

  # Set how frequently messages should be sent.
  #
  # The default, `1`, means send a message every second.
  config :interval, :validate => :number, :default => 1
  
  # The host of the MQTT broker
  config :mqttHost, :validate => :string, :default => "localhost", :required => true
  
  # The port that the MQTT broker is using
  config :port, :validate => :number, :default => 1883, :required => true
  
  # Whether the MQTT broker is using SSL or not.
  config :ssl, :validate => :boolean, :default => false
  
  # The topic that the plugin should subscribe to
  config :topic, validate => :string, :required => true

  public
  def register
    @host = Socket.gethostname
    @client = MQTT::Client.connect(
        :host => @mqttHost,
        :port => @port,
        :ssl => @ssl
        :client_id => MQTT::Client.generate_client_id("logstash-mqtt-input")
    )
  end # def register

  def run(queue)
#    Stud.interval(@interval) do
#      event = LogStash::Event.new("message" => @message, "host" => @host)
#      decorate(event)
#      queue << event
#    end # loop

    @client.get do |topic,message|
        #hej
        @codec.decode(message) do |event|
            event["host"] ||= @host
            event["topic"] = topic
            
            decorate(event)
            queue << event
        end
    end
    
    @client.subscribe(@topic)
  end # def run

end # class LogStash::Inputs::Example