require 'arduino_firmata'
require 'net/http'
require 'json'
require 'rainbow'

# user: 783

arduino = ArduinoFirmata.connect
last_submission_id = nil

print Rainbow("What's your Learn user ID?: ").bright

uid = gets.chomp
uri = URI("https://push.flatironschool.com:9443/ev/fis-user-#{uid}")

puts "Go forth and learn!"
puts ""

Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
  request = Net::HTTP::Get.new uri

  http.request(request) do |response|
    begin
      response.read_body do |chunk|
        if chunk.include?("submission_id")
          payload       = JSON.parse(chunk[6..-1])
          message       = payload["text"]
          params        = message.split("&")
          submission_id = params.find { |param| param.include? "submission_id" }.tap do |param|
            param.split("=").first
          end
          passed        = params.find { |param| param.include? "passing" }.tap do |param|
            param.split("=").first == "true"
          end

          if last_submission_id != submission_id
            if passed
              print Rainbow("\u25CF ").bright.green
              arduino.digital_write 13, true
              sleep 2
              arduino.digital_write 13, false
            else
              print Rainbow("\u25CF ").bright.red
            end
          end

          last_submission_id = submission_id
        end
      end
    rescue Interrupt
      puts "Bye!"
      exit 0
    end
  end
end
