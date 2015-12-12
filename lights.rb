require 'arduino_firmata'
require 'net/http'
require 'json'
require 'rainbow'

class Lights
  PINS = {
    green: 7,
    red:   8
  }

  def initialize(arduino, display)
    @arduino = arduino
    @display = display
  end

  def setup
    # ie. user: 783
    @display.print Rainbow("What's your Learn user ID?: ").bright

    @uid = gets.chomp
    @uri = URI("https://push.flatironschool.com:9443/ev/fis-user-#{@uid}")

    @display.puts "Go forth and learn!"
  end

  def run
    Net::HTTP.start(@uri.host, @uri.port, use_ssl: true) do |http|
      request  = Net::HTTP::Get.new(@uri)
      last_sid = nil

      http.request(request) do |response|
        response.read_body do |chunk|
          # We're only looking for submissions
          if chunk.include?("submission_id")
            params = parse_payload(chunk)
            sid    = params.find { |param| param.include? "submission_id" }.tap do |param|
              param.split("=").last
            end
            passed = params.find { |param| param.include? "passing=true" }

            if last_sid != sid
              lightup(passed)
            end
          end

          last_sid = sid
        end
      end
    end
  end

  private

  def parse_payload(chunk)
    payload = JSON.parse(chunk[6..-1])
    message = payload["text"]
    message.split("&")
  end

  def lightup(passed)
    color = passed ? :green : :red

    @display.print Rainbow("\u25CF ").bright.send(color)
    @arduino.digital_write PINS[color], true
    sleep 5
    @arduino.digital_write PINS[color], false
  end
end

arduino = ArduinoFirmata.connect
lights  = Lights.new(arduino, STDOUT)

lights.setup

begin
  lights.run
rescue Interrupt
  puts "Bye!"
  exit 0
end
