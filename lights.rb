require 'arduino_firmata'
require 'net/http'
require 'json'
require 'rainbow'

def parse_payload(chunk)
  payload = JSON.parse(chunk[6..-1])
  message = payload["text"]
  message.split("&")
end

def lightup(arduino, passed)
  color = passed ? :green : :red
  print Rainbow("\u25CF ").bright.send(color)

  2.times do 
    arduino.digital_write PINS[color], true
    sleep 1
    arduino.digital_write PINS[color], false
    sleep 1
  end
end

PINS = {
  green: 7,
  red:   8
}

arduino  = ArduinoFirmata.connect
last_sid = nil

# ie. user: 783
print Rainbow("What's your Learn user ID?: ").bright

uid = gets.chomp
uri = URI("https://push.flatironschool.com:9443/ev/fis-user-#{uid}")

puts "Go forth and learn!"

Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
  request = Net::HTTP::Get.new uri

  http.request(request) do |response|
    begin
      response.read_body do |chunk|
        if chunk.include?("submission_id")
          params = parse_payload(chunk)
          sid    = params.find { |param| param.include? "submission_id" }.tap do |param|
            param.split("=").last
          end
          passed = params.find { |param| param.include? "passing=true" }

          if last_sid != sid
            lightup(arduino, passed)
          end
        end

        last_sid = sid
      end
    rescue Interrupt
      puts "Bye!"
      exit 0
    end
  end
end
